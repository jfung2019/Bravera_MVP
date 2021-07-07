defmodule OmegaBravera.Offers do
  @moduledoc """
  The Offers context.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias Ecto.Multi
  alias OmegaBravera.Repo
  alias Absinthe.Relay

  alias OmegaBravera.Offers.{
    Offer,
    OfferChallenge,
    OfferVendor,
    OfferChallengeTeamMembers,
    OfferChallengeTeamInvitation,
    OfferChallengeTeam,
    OfferRedeem,
    OfferChallengeActivitiesM2m,
    OfferApproval,
    OfferGpsCoordinate
  }

  alias OmegaBravera.Points

  alias OmegaBravera.Activity.ActivityAccumulator
  alias OmegaBravera.Accounts.{User, AdminUser, Notifier}

  @doc """
  Admin dashboard offers information
  """
  def admin_dashboard_offers_info() do
    from(o in Offer,
      select: %{
        total_offers: fragment("TO_CHAR(?, '999,999')", count(o.id)),
        live_offers:
          fragment(
            "TO_CHAR(?, '999,999,999')",
            filter(
              count(o.id),
              o.approval_status == :approved and fragment("? > now()", o.end_date)
            )
          ),
        online_offers:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(o.id), o.offer_type == :online)),
        in_store_offers:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(o.id), o.offer_type == :in_store))
      }
    )
    |> Repo.one()
  end

  def dashboard_reward_info do
    from(r in OfferRedeem,
      inner_join: c in assoc(r, :offer_challenge),
      select: %{
        rewards_unlocked:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(r.id), c.status == "complete")),
        rewards_claimed:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(r.id), r.status == "redeemed"))
      }
    )
    |> Repo.one()
  end

  def buy_offer_with_points(offer, user) do
    Multi.new()
    |> Multi.run(:create_offer_challenge_with_points, fn _repo, _changes ->
      do_create_offer_challenge_with_points(offer, user)
    end)
    |> Multi.run(:deduct_points_from_user, fn _repo, _changes ->
      Points.do_deduct_points_from_user(user, offer)
    end)
    |> Multi.run(:add_expired_at, fn _repo,
                                     %{create_offer_challenge_with_points: %{offer_redeems: [r]}} ->
      case offer.redemption_days do
        nil ->
          {:ok, r}

        days ->
          expired_at = Timex.now() |> Timex.shift(days: days)
          update_offer_redeems(r, %{expired_at: expired_at})
      end
    end)
    |> Repo.transaction()
  end

  defp do_create_offer_challenge_with_points(offer, user) do
    OfferChallenge.buy_offer_challenge_with_points_changeset(offer, user)
    |> Repo.insert()
  end

  def list_offers_all_offers() do
    from(
      offer in Offer,
      order_by: [desc: offer.id]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of offers.

  ## Examples

      iex> list_offers()
      [%Offer{}, ...]

  """
  def list_offers(hidden \\ false, preloads \\ [:offer_challenges]) do
    now = Timex.now("Asia/Hong_Kong")

    from(
      offer in Offer,
      where: offer.hidden == ^hidden and offer.end_date > ^now,
      order_by: [desc: offer.id],
      preload: ^preloads
    )
    |> Repo.all()
  end

  def list_offers_by_organization(organization_id) do
    from(
      offer in Offer,
      where: offer.organization_id == ^organization_id,
      order_by: [desc: offer.id]
    )
    |> Repo.all()
  end

  def open_offers_query(now) do
    from(
      offer in Offer,
      left_join: op in assoc(offer, :offer_partners),
      where:
        offer.hidden == false and offer.end_date > ^now and is_nil(op.id) and
          offer.approval_status == :approved
    )
  end

  def closed_offers_query(now, user_id) do
    from(
      offer in Offer,
      right_join: p in assoc(offer, :partners),
      right_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      where: offer.end_date > ^now and not is_nil(m.id) and offer.approval_status == :approved
    )
  end

  @doc """
  Only shows offers that don't have a partner
  or if the user is a member of a partner, then the offer will be shown.
  """
  def list_offers_for_user(user_id) do
    now = Timex.now()

    unioned_query = union(open_offers_query(now), ^closed_offers_query(now, user_id))

    from(o in subquery(unioned_query), order_by: [desc: o.inserted_at])
    |> Repo.all()
  end

  def search_offers_for_user_paginated(keyword, location_id, coordinate, user_id, pagination_args) do
    now = Timex.now()

    open_offers = search_open_offers_query(now, keyword, location_id, coordinate)

    close_offers = search_closed_offers_query(now, user_id, keyword, location_id, coordinate)

    unioned_query = union(open_offers, ^close_offers)

    result =
      from(o in subquery(unioned_query), order_by: [desc: o.inserted_at])
      |> Relay.Connection.from_query(&Repo.all/1, pagination_args)

    case result do
      {:ok, ok_map} ->
        result_map =
          ok_map
          |> Map.put(:keyword, keyword)
          |> Map.put(:location_id, location_id)

        {:ok, result_map}

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  defp search_open_offers_query(now, keyword, nil, nil) do
    search = "%#{keyword}%"

    from(
      offer in Offer,
      left_join: op in assoc(offer, :offer_partners),
      where:
        offer.hidden == false and offer.end_date > ^now and is_nil(op.id) and
          offer.approval_status == :approved and ilike(offer.name, ^search)
    )
  end

  defp search_open_offers_query(now, keyword, location_id, nil) do
    search = "%#{keyword}%"

    from(
      offer in Offer,
      left_join: op in assoc(offer, :offer_partners),
      left_join: ol in assoc(offer, :offer_locations),
      where:
        offer.hidden == false and offer.end_date > ^now and is_nil(op.id) and
          offer.approval_status == :approved and ilike(offer.name, ^search) and
          ol.location_id == ^location_id
    )
  end

  defp search_open_offers_query(now, keyword, location_id, %{longitude: long, latitude: lat}) do
    search = "%#{keyword}%"
    geom = %Geo.Point{coordinates: {long, lat}, srid: 4326}

    from(
      offer in Offer,
      left_join: op in assoc(offer, :offer_partners),
      left_join: ol in assoc(offer, :offer_locations),
      left_join: oc in assoc(offer, :offer_gps_coordinates),
      where:
        offer.hidden == false and offer.end_date > ^now and is_nil(op.id) and
          offer.approval_status == :approved and ilike(offer.name, ^search) and
          (ol.location_id == ^location_id or st_dwithin_in_meters(oc.geom, ^geom, 50000))
    )
  end

  defp search_closed_offers_query(now, user_id, keyword, nil, nil) do
    search = "%#{keyword}%"

    from(
      offer in Offer,
      right_join: p in assoc(offer, :partners),
      right_join: m in assoc(p, :members),
      on: m.user_id == ^user_id,
      where:
        offer.end_date > ^now and not is_nil(m.id) and offer.approval_status == :approved and
          ilike(offer.name, ^search)
    )
  end

  defp search_closed_offers_query(now, user_id, keyword, location_id, nil) do
    search = "%#{keyword}%"

    from(
      offer in Offer,
      right_join: p in assoc(offer, :partners),
      right_join: m in assoc(p, :members),
      left_join: ol in assoc(offer, :offer_locations),
      on: m.user_id == ^user_id,
      where:
        offer.end_date > ^now and not is_nil(m.id) and offer.approval_status == :approved and
          ilike(offer.name, ^search) and ol.location_id == ^location_id
    )
  end

  defp search_closed_offers_query(now, user_id, keyword, location_id, %{
         longitude: long,
         latitude: lat
       }) do
    search = "%#{keyword}%"
    geom = %Geo.Point{coordinates: {long, lat}, srid: 4326}

    from(
      offer in Offer,
      right_join: p in assoc(offer, :partners),
      right_join: m in assoc(p, :members),
      left_join: ol in assoc(offer, :offer_locations),
      left_join: oc in assoc(offer, :offer_gps_coordinates),
      on: m.user_id == ^user_id,
      where:
        offer.end_date > ^now and not is_nil(m.id) and offer.approval_status == :approved and
          ilike(offer.name, ^search) and
          (ol.location_id == ^location_id or st_dwithin_in_meters(oc.geom, ^geom, 50000))
    )
  end

  @doc """
  Pagination online offers
  """
  def paginate_offers(params) do
    list_offers_preload_query([
      :vendor,
      :offer_challenges,
      offer_redeems: [:offer_reward]
    ])
    |> Turbo.Ecto.turbo(params, entry_name: "offers")
  end

  def paginate_offers("online", organization_id, params) do
    org_offers_pagination(:online, organization_id, params)
  end

  def paginate_offers("in_store", organization_id, params) do
    org_offers_pagination(:in_store, organization_id, params)
  end

  defp org_offers_pagination(offer_type, organization_id, params) do
    list_offers_preload_query([
      :vendor,
      :offer_challenges,
      offer_redeems: [:offer_reward]
    ])
    |> where([o], o.offer_type == ^offer_type and o.organization_id == ^organization_id)
    |> Turbo.Ecto.turbo(params, entry_name: "offers")
  end

  def total_offers_query() do
    from(o in Offer, select: count(o.id))
  end

  def total_offers() do
    total_offers_query()
    |> Repo.one()
  end

  def total_live_offers() do
  end

  def total_online_offers() do
    total_offers_query()
    |> where([o], o.offer_type == :online)
    |> Repo.one()
  end

  def total_in_store_offers() do
    total_offers_query()
    |> where([o], o.offer_type == :in_store)
    |> Repo.one()
  end

  @doc """
  Gets a single offer.

  Raises `Ecto.NoResultsError` if the Offer does not exist.

  ## Examples

      iex> get_offer!(123)
      %Offer{}

      iex> get_offer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer!(id, preloads \\ []) do
    from(o in Offer, where: o.id == ^id, preload: ^preloads)
    |> Repo.one!()
  end

  def check_first_10_offer_image(org_id) do
    from(o in Offer, where: o.organization_id == ^org_id, select: count(o.id) <= 10)
    |> Repo.one()
  end

  def check_offer_no_reward(org_id) do
    from(
      o in Offer,
      left_join: reward in assoc(o, :offer_rewards),
      where: o.organization_id == ^org_id and is_nil(reward.id),
      select: count(o.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  Gets an offer by the offer slug.
  """
  def get_offer_by_slug(
        slug,
        preloads \\ [:offer_challenges, :offer_locations, :offer_gps_coordinates]
      ) do
    from(o in Offer,
      where: o.slug == ^slug,
      left_join: offer_challenges in assoc(o, :offer_challenges),
      on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
      preload: ^preloads,
      group_by: [o.id],
      select: %{o | active_offer_challenges: count(offer_challenges.id)}
    )
    |> Repo.one()
    |> prepare_offer()
  end

  @doc """
  Gets an offer by slug and organization_id.
  """
  def get_offer_by_slug_and_organization_id(
        slug,
        organization_id,
        preloads \\ [:offer_challenges]
      ) do
    from(o in Offer,
      where: o.slug == ^slug and o.organization_id == ^organization_id,
      left_join: offer_challenges in assoc(o, :offer_challenges),
      on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
      preload: ^preloads,
      group_by: [o.id],
      select: %{o | active_offer_challenges: count(offer_challenges.id)}
    )
    |> Repo.one()
    |> prepare_offer()
  end

  @doc """
  Gets an offer if it's allowed by the user, or else return `:not_authorized`.
  """
  def get_allowed_offer_by_slug_and_user_id(slug, user_id) do
    devices =
      from(u in User,
        left_join: d in assoc(u, :devices),
        where: u.id == ^user_id and d.active == true,
        group_by: u.id,
        select: count(d.id)
      )
      |> Repo.one()

    if devices <= 0 or devices == nil do
      :no_active_device
    else
      return_value =
        from(o in Offer,
          where: o.slug == ^slug,
          left_join: offer_challenges in OfferChallenge,
          on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
          preload: [:offer_challenges],
          left_join: p in assoc(o, :partners),
          left_join: m in assoc(p, :members),
          on: m.user_id == ^user_id,
          group_by: [o.id, p.id, m.id],
          order_by:
            fragment(
              "(CASE WHEN ? THEN ? WHEN ? IS NOT NULL THEN ? ELSE ? END) DESC",
              is_nil(p.id),
              true,
              m.id,
              true,
              false
            ),
          limit: 1,
          select: %{
            can_join:
              fragment(
                "CASE WHEN ? THEN ? WHEN ? IS NOT NULL THEN ? ELSE ? END",
                is_nil(p.id),
                true,
                m.id,
                true,
                false
              ),
            offer: %{o | active_offer_challenges: count(offer_challenges.id)}
          }
        )
        |> Repo.one()

      case return_value do
        %{can_join: true, offer: offer} ->
          prepare_offer(offer)

        %{can_join: false} ->
          :not_authorized

        %{offer: offer} ->
          offer
      end
    end
  end

  defp prepare_offer(offer) do
    cond do
      offer == nil ->
        nil

      Timex.is_valid?(offer.pre_registration_start_date) ->
        offer
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(offer.pre_registration_start_date)
        )

      true ->
        offer
    end
  end

  def get_offer_chal_by_slugs(offer_slug, slug, preloads \\ [:offer]) do
    query =
      from(oc in OfferChallenge,
        join: offer in Offer,
        on: oc.offer_id == offer.id,
        left_join: a in OfferChallengeActivitiesM2m,
        on: oc.id == a.offer_challenge_id,
        left_join: ac in ActivityAccumulator,
        on: a.activity_id == ac.id,
        where: oc.slug == ^slug and offer.slug == ^offer_slug,
        preload: ^preloads,
        group_by: oc.id,
        select: %{oc | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance)}
      )

    Repo.one(query)
  end

  def get_offer_by_slug_for_panel(
        slug,
        preloads \\ [:offer_challenges, :offer_locations, :offer_gps_coordinates]
      ) do
    offer =
      from(o in Offer,
        where: o.slug == ^slug,
        left_join: offer_challenges in assoc(o, :offer_challenges),
        on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
        preload: ^preloads,
        group_by: [o.id],
        select: %{o | active_offer_challenges: count(offer_challenges.id)}
      )
      |> Repo.one()

    offer =
      offer
      |> Map.put(:start_date, Timex.to_datetime(offer.start_date))
      |> Map.put(:end_date, Timex.to_datetime(offer.end_date))

    case Timex.is_valid?(offer.pre_registration_start_date) do
      true ->
        offer
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(offer.pre_registration_start_date)
        )

      _ ->
        offer
    end
  end

  def get_monthly_statement_for_organization_offer(slug, organization_id, month, year) do
    {:ok, start_date} = Date.new(String.to_integer(year), String.to_integer(month), 1)
    start_date = Timex.to_datetime(start_date)
    end_date = Timex.shift(start_date, months: 1)

    rows =
      from(r in OfferRedeem,
        join: o in assoc(r, :offer),
        join: u in assoc(r, :user),
        join: oc in assoc(r, :offer_challenge),
        left_join: ofr in assoc(r, :offer_reward),
        where:
          o.slug == ^slug and o.organization_id == ^organization_id and
            r.updated_at >= ^start_date and
            r.updated_at <= ^end_date,
        order_by: [desc: r.updated_at],
        select: [
          u.username,
          fragment("TO_CHAR(?, 'D/M/YY HH24:MI')", oc.inserted_at),
          fragment(
            "CASE WHEN ? = 'complete' THEN TO_CHAR(?, 'D/M/YY HH24:MI') ELSE '' END",
            oc.status,
            oc.updated_at
          ),
          fragment(
            "CASE WHEN ? = 'redeemed' THEN TO_CHAR(?, 'D/M/YY HH24:MI') ELSE '' END",
            r.status,
            r.updated_at
          ),
          ofr.name
        ]
      )
      |> Repo.all()

    ([organization_statement_headers()] ++ rows)
    |> CSV.encode()
    |> Enum.to_list()
    |> to_string()
  end

  def get_monthly_statement_for_offer(slug, start_date, end_date) do
    offer = get_offer_by_slug(slug, [])

    from(
      redeem in OfferRedeem,
      where:
        redeem.offer_id == ^offer.id and redeem.updated_at >= ^start_date and
          redeem.updated_at <= ^end_date,
      join: user in assoc(redeem, :user),
      join: oc in assoc(redeem, :offer_challenge),
      left_join: reward in assoc(redeem, :offer_reward),
      order_by: [desc: redeem.updated_at],
      select: [
        oc.slug,
        user.firstname,
        user.lastname,
        user.email,
        fragment(
          "to_char(timezone('Asia/Hong_Kong', ?), 'YYYY-mm-dd HH24:MI:SS')",
          oc.inserted_at
        ),
        fragment(
          "CASE WHEN ? = 'complete' THEN to_char(timezone('Asia/Hong_Kong', ?), 'YYYY-mm-dd HH24:MI:SS') ELSE '' END",
          oc.status,
          oc.updated_at
        ),
        oc.has_team,
        fragment(
          "CASE WHEN ? = 'redeemed' THEN to_char(timezone('Asia/Hong_Kong', ?), 'YYYY-mm-dd HH24:MI:SS') ELSE '-' END",
          redeem.status,
          redeem.updated_at
        ),
        reward.name
      ]
    )
    |> Repo.all()
  end

  @doc """
  check if there is new offer inserted since the given datetime
  """
  @spec new_offer_since(Datetime.t(), integer()) :: boolean()
  def new_offer_since(nil, _location_id), do: false

  def new_offer_since(datetime, location_id) do
    from(o in Offer,
      left_join: ol in assoc(o, :offer_locations),
      where: o.inserted_at > ^datetime and ol.location_id == ^location_id,
      select: count(o.id) > 0
    )
    |> Repo.one()
  end

  def new_offer_since(datetime, location_id, long, lat) do
    geom = %Geo.Point{coordinates: {long, lat}, srid: 4326}

    from(o in Offer,
      left_join: ol in assoc(o, :offer_locations),
      left_join: oc in assoc(o, :offer_gps_coordinates),
      where:
        o.inserted_at > ^datetime and
          (ol.location_id == ^location_id or st_dwithin_in_meters(oc.geom, ^geom, 50000)),
      select: count(o.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  Creates a offer.

  ## Examples

      iex> create_offer(%{field: value})
      {:ok, %Offer{}}

      iex> create_offer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
  end

  def create_org_online_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.org_online_offer_changeset(attrs)
    |> check_org_merchant()
    |> Repo.insert()
  end

  def create_org_offline_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.org_offline_offer_changeset(attrs)
    |> check_org_merchant()
    |> Repo.insert()
  end

  @spec check_org_merchant(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp check_org_merchant(%{changes: %{organization_id: org_id}} = changeset),
      do: do_check_org_merchant(changeset, org_id)

  defp check_org_merchant(%{data: %{organization_id: org_id}} = changeset),
      do: do_check_org_merchant(changeset, org_id)

  @spec do_check_org_merchant(Ecto.Changeset.t(), term) :: Ecto.Changeset.t()
  defp do_check_org_merchant(changeset, org_id) do
    case OmegaBravera.Accounts.get_organization!(org_id) do
      %{account_type: :merchant} ->
        Offer.check_merchant_start_end_date(changeset)
        |> Offer.check_merchant_can_update(:merchant)

      %{account_type: type} ->
        Offer.check_merchant_can_update(changeset, type)
    end
  end

  def create_offer_approval(attrs \\ %{}) do
    case OfferApproval.changeset(%OfferApproval{}, attrs) do
      %{valid?: true} = changeset ->
        offer_approval =
          changeset
          |> Ecto.Changeset.apply_changes()

        offer = get_offer!(offer_approval.offer_id, [:organization])
        update_params = check_start_end_date(offer, %{approval_status: offer_approval.status})
        {:ok, _offer} = update_offer(offer, update_params)

        {:ok, changeset}

      changeset ->
        {:error, changeset}
    end
  end

  def change_offer_approval(%OfferApproval{} = offer_approval, attr \\ %{}) do
    OfferApproval.changeset(offer_approval, attr)
  end

  @spec check_start_end_date(Offer.t(), map) :: map
  defp check_start_end_date(%{organization: %{account_type: :merchant}} = offer, params) do
    now = Timex.now()
    cond do
      Timex.diff(offer.start_date, now) < 0 ->
        params
        |> Map.put(:start_date, now)
        |> Map.put(:end_date, Timex.shift(now, days: Timex.diff(offer.end_date, offer.start_date, :days)))

      true ->
        params
    end
  end

  defp check_start_end_date(_offer, params), do: params

  @doc """
  Updates a offer.

  ## Examples

      iex> update_offer(offer, %{field: new_value})
      {:ok, %Offer{}}

      iex> update_offer(offer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer(%Offer{} = offer, attrs) do
    result =
      offer
      |> Offer.changeset(attrs)
      |> Repo.update()

    case {offer.approval_status, result} do
      # If no Organization, then we don't care.
      {_, {:ok, %{organization_id: nil}} = result} ->
        result

      # If org and from pending to approved or denied
      {:pending, {:ok, %{approval_status: status} = updated_offer} = result}
      when status in [:approved, :denied] ->
        OmegaBravera.Accounts.get_partner_user_email_by_offer(updated_offer.id)
        |> Notifier.notify_customer_offer_email(
          %OfferApproval{status: status, message: ""},
          updated_offer
        )

        result

      {_, result} ->
        result
    end
  end

  def update_org_online_offer(%Offer{} = offer, attrs) do
    offer
    |> Offer.org_online_offer_changeset(attrs)
    |> check_org_merchant()
    |> Repo.update()
  end

  def update_org_offline_offer(%Offer{} = offer, attrs) do
    offer
    |> Offer.org_offline_offer_changeset(attrs)
    |> check_org_merchant()
    |> Repo.update()
  end

  @doc """
  Deletes a Offer.

  ## Examples

      iex> delete_offer(offer)
      {:ok, %Offer{}}

      iex> delete_offer(offer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer(%Offer{} = offer) do
    Repo.delete(offer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer changes.

  ## Examples

      iex> change_offer(offer)
      %Ecto.Changeset{source: %Offer{}}

  """
  def change_offer(%Offer{} = offer) do
    Offer.changeset(offer, %{})
  end

  alias OmegaBravera.Offers.OfferChallenge

  @doc """
  Returns the list of offer_challenges.

  ## Examples

      iex> list_offer_challenges()
      [%OfferChallenge{}, ...]

  """
  def list_offer_challenges do
    Repo.all(OfferChallenge)
  end

  def list_offers_preload_query(preloads \\ [:vendor]) do
    from(
      o in Offer,
      left_join: challenge in assoc(o, :offer_challenges),
      left_join:
        user_challenge in subquery(
          from(oc in OfferChallenge,
            distinct: [oc.user_id, oc.offer_id],
            select: %{id: oc.id, user_id: oc.user_id}
          )
        ),
      on: challenge.id == user_challenge.id,
      preload: ^preloads,
      order_by: o.inserted_at,
      windows: [group_id: [partition_by: o.id]],
      distinct: true,
      select: %{o | unique_participants: over(count(user_challenge.user_id), :group_id)}
    )
  end

  def list_offer_offer_challenges(offer_id) do
    from(
      oc in OfferChallenge,
      left_join: a in OfferChallengeActivitiesM2m,
      on: oc.id == a.offer_challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      where: oc.offer_id == ^offer_id,
      group_by: [oc.id],
      preload: [user: [:strava]],
      select: %{
        oc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance)
      }
    )
    |> Repo.all()
  end

  def offer_offer_challenges_paginated(offer_id, pagination_args) do
    from(
      oc in OfferChallenge,
      left_join: a in OfferChallengeActivitiesM2m,
      on: oc.id == a.offer_challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      where: oc.offer_id == ^offer_id,
      group_by: [oc.id],
      preload: [user: [:strava]],
      order_by: [desc: oc.inserted_at],
      select: %{
        oc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance)
      }
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  def get_redeem(challenge_id, user_id) do
    from(
      redeem in OfferRedeem,
      where: redeem.offer_challenge_id == ^challenge_id and redeem.user_id == ^user_id
    )
    |> Repo.one()
  end

  @doc """
  Gets a single offer_challenge.

  Raises `Ecto.NoResultsError` if the Offer challenge does not exist.

  ## Examples

      iex> get_offer_challenge!(123)
      %OfferChallenge{}

      iex> get_offer_challenge!(456)
      ** (Ecto.NoResultsError)

  """

  def get_live_offer_challenges() do
    from(
      oc in OfferChallenge,
      where: oc.status == "pre_registration" and oc.start_date < ^Timex.now()
    )
    |> Repo.all()
  end

  def get_offer_challenge!(id) do
    from(oc in OfferChallenge,
      left_join: a in OfferChallengeActivitiesM2m,
      on: ^id == a.offer_challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      group_by: oc.id,
      select: %{oc | distance_covered: fragment("sum(coalesce(?,0))", ac.distance)},
      where: oc.id == ^id
    )
    |> Repo.one!()
  end

  def get_user_offer_challenges(user_id, preloads \\ [:offer]) do
    from(
      oc in OfferChallenge,
      where: oc.user_id == ^user_id,
      left_join: a in OfferChallengeActivitiesM2m,
      on: oc.id == a.offer_challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      preload: ^preloads,
      order_by: [desc: :start_date],
      group_by: oc.id,
      select: %{
        oc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance)
      }
    )
    |> Repo.all()
  end

  @doc """
  Creates a offer_challenge by using the offer and user.
  """
  def create_offer_challenge(
        %Offer{} = offer,
        %User{} = user,
        attrs \\ %{team: %{}, offer_redeems: [%{}], payment: %{}}
      ) do
    %OfferChallenge{}
    |> OfferChallenge.create_changeset(offer, user, attrs)
    |> Repo.insert()
  end

  @doc """
  Override creation of offer challenge to create challenges for users
  by bypassing payments, etc.
  """
  def create_offer_challenge_with_bypass(%Offer{} = offer, %User{} = user) do
    {:ok, offer_challenge} =
      %OfferChallenge{}
      |> OfferChallenge.bare_changeset_without_payment(offer, user, %{
        team: %{},
        offer_redeems: [%{}],
        payment: %{}
      })
      |> Repo.insert()

    OmegaBraveraWeb.Offer.OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))
  end

  def create_offer_challenge_with_team(
        %OfferChallenge{} = offer_challenge,
        %Offer{} = offer,
        %User{} = user,
        attrs \\ %{}
      ) do
    offer_challenge
    |> OfferChallenge.create_with_team_changeset(offer, user, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a offer_challenge.

  ## Examples

      iex> update_offer_challenge(offer_challenge, %{field: new_value})
      {:ok, %OfferChallenge{}}

      iex> update_offer_challenge(offer_challenge, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer_challenge(%OfferChallenge{} = offer_challenge, attrs) do
    offer_challenge
    |> OfferChallenge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a OfferChallenge.

  ## Examples

      iex> delete_offer_challenge(offer_challenge)
      {:ok, %OfferChallenge{}}

      iex> delete_offer_challenge(offer_challenge)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer_challenge(%OfferChallenge{} = offer_challenge) do
    Repo.delete(offer_challenge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer_challenge changes.

  ## Examples

      iex> change_offer_challenge(offer_challenge)
      %Ecto.Changeset{source: %OfferChallenge{}}

  """
  def change_offer_challenge(%OfferChallenge{} = offer_challenge) do
    OfferChallenge.changeset(offer_challenge, %{})
  end

  def get_team_member_activity_totals(challenge_id, users_list \\ []) do
    user_ids = Enum.map(users_list, & &1.id)

    team_activities =
      from(
        activity_relation in OfferChallengeActivitiesM2m,
        where: activity_relation.offer_challenge_id == ^challenge_id,
        left_join: activity in ActivityAccumulator,
        on: activity_relation.activity_id == activity.id and activity.user_id in ^user_ids,
        preload: [:activity]
      )
      |> Repo.all()

    Enum.reduce(user_ids, %{}, fn uid, acc ->
      total_distance_for_team_member_activity =
        Enum.filter(team_activities, &(uid == &1.activity.user_id))
        |> Enum.reduce(Decimal.new(0), fn activity_relation, total_distance ->
          Decimal.add(activity_relation.activity.distance, total_distance)
          |> Decimal.round(1)
        end)

      Map.put(acc, uid, total_distance_for_team_member_activity)
    end)
  end

  def latest_activities(
        %OfferChallenge{} = challenge,
        limit \\ nil,
        preloads \\ [user: [:strava]]
      ) do
    query =
      from(
        activity in ActivityAccumulator,
        join: activity_relation in OfferChallengeActivitiesM2m,
        on: activity.id == activity_relation.activity_id,
        where: activity_relation.offer_challenge_id == ^challenge.id,
        preload: ^preloads,
        order_by: [desc: :start_date]
      )

    query =
      if !is_nil(limit) and is_number(limit) and limit > 0 do
        limit(query, ^limit)
      else
        query
      end

    Repo.all(query)
  end

  alias OmegaBravera.Offers.OfferReward

  @doc """
  Returns the list of offer_rewards.

  ## Examples

      iex> list_offer_rewards()
      [%OfferReward{}, ...]

  """
  def list_offer_rewards do
    from(o in OfferReward, where: o.hide == false)
    |> Repo.all()
  end

  def admin_list_offer_rewards do
    Repo.all(OfferReward)
  end

  def admin_list_offer_rewards_query(preloads \\ []) do
    from(o in OfferReward, preload: ^preloads)
  end

  @doc "Get offer rewards of the given offer id"
  def list_offer_rewards_by_offer_id(offer_id) do
    from(o in OfferReward, where: o.offer_id == ^offer_id and o.hide == false)
    |> Repo.all()
  end

  @doc """
  paginate offer rewards based on login user type
  """
  def paginate_offer_rewards(%AdminUser{}, params) do
    Turbo.Ecto.turbo(admin_list_offer_rewards_query([:offer]), params, entry_name: "offer_rewards")
  end

  def paginate_offer_rewards(organization_id, params) do
    from(o in OfferReward,
      left_join: offer in assoc(o, :offer),
      where: offer.organization_id == ^organization_id,
      preload: [:offer]
    )
    |> Turbo.Ecto.turbo(params, entry_name: "offer_rewards")
  end

  @doc """
  Gets a single offer_reward.

  Raises `Ecto.NoResultsError` if the Offer reward does not exist.

  ## Examples

      iex> get_offer_reward!(123)
      %OfferReward{}

      iex> get_offer_reward!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer_reward!(id), do: Repo.get!(OfferReward, id)

  def new_reward_created(organization_id) do
    from(r in OfferReward,
      join: o in assoc(r, :offer),
      where:
        o.organization_id == ^organization_id and
          fragment("? BETWEEN now() - interval '1 minute' AND now()", r.inserted_at),
      select: count(r.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  Creates a offer_reward.

  ## Examples

      iex> create_offer_reward(%{field: value})
      {:ok, %OfferReward{}}

      iex> create_offer_reward(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer_reward(attrs \\ %{}) do
    %OfferReward{}
    |> OfferReward.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a offer_reward.

  ## Examples

      iex> update_offer_reward(offer_reward, %{field: new_value})
      {:ok, %OfferReward{}}

      iex> update_offer_reward(offer_reward, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer_reward(%OfferReward{} = offer_reward, attrs) do
    offer_reward
    |> OfferReward.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a OfferReward.

  ## Examples

      iex> delete_offer_reward(offer_reward)
      {:ok, %OfferReward{}}

      iex> delete_offer_reward(offer_reward)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer_reward(%OfferReward{} = offer_reward) do
    Repo.delete(offer_reward)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer_reward changes.

  ## Examples

      iex> change_offer_reward(offer_reward)
      %Ecto.Changeset{source: %OfferReward{}}

  """
  def change_offer_reward(%OfferReward{} = offer_reward) do
    OfferReward.changeset(offer_reward, %{})
  end

  alias OmegaBravera.Offers.OfferRedeem

  @doc """
  Returns the list of offer_redeems.

  ## Examples

      iex> list_offer_redeems()
      [%OfferRedeem{}, ...]

  """
  def list_offer_redeems(preloads \\ []) do
    from(
      redeem in OfferRedeem,
      preload: ^preloads
    )
    |> Repo.all()
  end

  @doc """
  Lists offer_redeems used in offer statement.
  """
  def list_offer_redeems_for_offer_statement(slug, preloads \\ []) do
    offer = get_offer_by_slug(slug)

    from(
      redeem in OfferRedeem,
      where: redeem.offer_id == ^offer.id,
      preload: ^preloads,
      order_by: [desc: redeem.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists offer_redeems used in offer statement.
  """
  def list_offer_redeems_for_offer_statement_by_organization(slug, organization_id) do
    from(r in OfferRedeem,
      join: o in assoc(r, :offer),
      where: o.slug == ^slug and o.organization_id == ^organization_id,
      preload: [:offer, :offer_challenge, :user, :offer_reward],
      order_by: [desc: r.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Headers for Statement.
  """
  def organization_statement_headers,
    do: [
      "Alias/Username",
      "Challenge Creation",
      "Challenge Completed Date",
      "Redeemed Date",
      "Reward Name"
    ]

  @doc """
  Lists all expired offer redeems for a user
  """
  def list_expired_offer_redeems(user_id) do
    from(
      r in OfferRedeem,
      where: r.user_id == ^user_id and r.status == "expired"
    )
    |> Repo.all()
  end

  @doc """
  Gets a single offer_redeems.

  Raises `Ecto.NoResultsError` if the Offer redeems does not exist.

  ## Examples

      iex> get_offer_redeems!(123)
      %OfferRedeem{}

      iex> get_offer_redeems!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer_redeems!(id), do: Repo.get!(OfferRedeem, id)

  def get_offer_redeems!(id, preloads) do
    from(o in OfferRedeem, where: o.id == ^id, preload: ^preloads)
    |> Repo.one!()
  end

  @doc """
  Creates a offer_redeems.

  ## Examples

      iex> create_offer_redeems(%{field: value})
      {:ok, %OfferRedeem{}}

      iex> create_offer_redeems(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer_redeems(
        %OfferChallenge{} = offer_challenge,
        vendor,
        attrs \\ %{},
        team_user \\ %User{}
      ) do
    %OfferRedeem{}
    |> OfferRedeem.create_changeset(offer_challenge, vendor, attrs, team_user)
    |> Repo.insert()
  end

  def get_offer_completed_redeems_count_by_offer_id(offer_id) do
    from(
      redeem in OfferRedeem,
      where: redeem.offer_id == ^offer_id and redeem.status == ^"redeemed",
      select: count(redeem.id, :distinct)
    )
    |> Repo.one()
  end

  @doc """
  Get offer_redeem by offer_challenge's slug and user_id
  """
  def get_offer_redeem_by_slug_user_id(offer_challenge_slug, user_id) do
    from(r in OfferRedeem,
      left_join: o in assoc(r, :offer_challenge),
      where: o.slug == ^offer_challenge_slug and r.user_id == ^user_id
    )
    |> Repo.one()
  end

  @doc """
  Updates a offer_redeems.

  ## Examples

      iex> update_offer_redeems(offer_redeems, %{field: new_value})
      {:ok, %OfferRedeem{}}

      iex> update_offer_redeems(offer_redeems, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer_redeems(offer_redeem, attrs) do
    OfferRedeem.changeset(offer_redeem, attrs)
    |> Repo.update()
  end

  @doc """
  Updates an offer redeem when updating for redemption purposes.
  """
  def update_offer_redeems(offer_redeems, offer_challenge, offer, vendor, attrs) do
    offer_redeems
    |> OfferRedeem.redeem_reward_changeset(offer_challenge, offer, vendor, attrs)
    |> Repo.update()
  end

  @doc """
  Confirm online offer is redeemed and add bonus points for user
  """
  @spec confirm_online_offer_redeem(OfferRedeem.t()) :: tuple
  def confirm_online_offer_redeem(offer_redeem) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:redeem, OfferRedeem.changeset(offer_redeem, %{status: "redeemed"}))
    |> Ecto.Multi.run(:point, fn _repo, %{redeem: %{id: redeem_id, user_id: user_id}} ->
      Points.create_bonus_points(%{
        user_id: user_id,
        source: :redeem,
        value: Points.Point.get_redeem_back_points()
      })
      |> notify_user_for_reward_points(redeem_id)
    end)
    |> Repo.transaction()
  end

  @spec notify_user_for_reward_points(tuple, term) :: tuple
  defp notify_user_for_reward_points({:ok, _point} = result, redeem_id) do
    %{"redeem_id" => redeem_id}
    |> OmegaBravera.Offers.Jobs.NotifyUserPointsRewarded.new()
    |> Oban.insert()

    result
  end

  defp notify_user_for_reward_points(result, _redeem_id), do: result

  @doc """
  Deletes a OfferRedeem.

  ## Examples

      iex> delete_offer_redeems(offer_redeems)
      {:ok, %OfferRedeem{}}

      iex> delete_offer_redeems(offer_redeems)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer_redeems(%OfferRedeem{} = offer_redeems) do
    Repo.delete(offer_redeems)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer_redeems changes.

  ## Examples

      iex> change_offer_redeems(offer_redeems)
      %Ecto.Changeset{source: %OfferRedeem{}}

  """
  def change_offer_redeems(%OfferRedeem{} = offer_redeem, attrs \\ %{}) do
    OfferRedeem.changeset(offer_redeem, attrs)
  end

  @doc """
  Expires any offer redeems that have an expired_at field filled in and expired.
  """
  def expire_expired_offer_redeems do
    now = Timex.now()

    from(o in OfferRedeem,
      where: not is_nil(o.expired_at) and o.expired_at <= ^now and o.status == "pending"
    )
    |> Repo.update_all(set: [status: "expired"])
  end

  @doc """
  query for listing offer vendors
  """
  def list_offer_vendors_query() do
    from(o in OfferVendor, order_by: [desc: o.inserted_at])
  end

  @doc """
  Returns the list of offer_vendors.

  ## Examples

      iex> list_offer_vendors()
      [%OfferVendor{}, ...]

  """
  def list_offer_vendors do
    list_offer_vendors_query()
    |> Repo.all()
  end

  def list_offer_vendors_by_organization_query(organization_id) do
    list_offer_vendors_query()
    |> where([o], o.organization_id == ^organization_id)
  end

  def list_offer_vendors_by_organization(organization_id) do
    list_offer_vendors_by_organization_query(organization_id)
    |> Repo.all()
  end

  def created_first_vendor?(organization_id) do
    # only 1 offer vendor belongs to the organization
    # that vendor is not attached to any offer
    from(ov in OfferVendor,
      left_join: o in assoc(ov, :offers),
      where: is_nil(o.id) and ov.organization_id == ^organization_id,
      select: count(ov.id) == 1
    )
    |> Repo.one()
  end

  @doc """
  paginate offer vendors based on login user type
  """
  def paginate_offer_vendors(%AdminUser{}, params) do
    Turbo.Ecto.turbo(list_offer_vendors_query(), params, entry_name: "offer_vendors")
  end

  def paginate_offer_vendors(organization_id, params) do
    list_offer_vendors_by_organization_query(organization_id)
    |> Turbo.Ecto.turbo(params, entry_name: "offer_vendors")
  end

  @doc """
  Gets a single offer_vendor.

  Raises `Ecto.NoResultsError` if the Offer vendor does not exist.

  ## Examples

      iex> get_offer_vendor!(123)
      %OfferVendor{}

      iex> get_offer_vendor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer_vendor!(id, preloads \\ []) do
    from(ov in OfferVendor, where: ov.id == ^id, preload: ^preloads)
    |> Repo.one!()
  end

  @doc """
  Creates a offer_vendor.

  ## Examples

      iex> create_offer_vendor(%{field: value})
      {:ok, %OfferVendor{}}

      iex> create_offer_vendor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer_vendor(attrs \\ %{}) do
    %OfferVendor{}
    |> OfferVendor.changeset(attrs)
    |> Repo.insert()
  end

  def create_org_offer_vendor(attrs \\ %{}) do
    %OfferVendor{}
    |> OfferVendor.org_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a offer_vendor.

  ## Examples

      iex> update_offer_vendor(offer_vendor, %{field: new_value})
      {:ok, %OfferVendor{}}

      iex> update_offer_vendor(offer_vendor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer_vendor(%OfferVendor{} = offer_vendor, attrs) do
    offer_vendor
    |> OfferVendor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a OfferVendor.

  ## Examples

      iex> delete_offer_vendor(offer_vendor)
      {:ok, %OfferVendor{}}

      iex> delete_offer_vendor(offer_vendor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer_vendor(%OfferVendor{} = offer_vendor) do
    Repo.delete(offer_vendor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer_vendor changes.

  ## Examples

      iex> change_offer_vendor(offer_vendor)
      %Ecto.Changeset{source: %OfferVendor{}}

  """
  def change_offer_vendor(%OfferVendor{} = offer_vendor) do
    OfferVendor.changeset(offer_vendor, %{})
  end

  def add_user_to_team(
        %OfferChallengeTeamInvitation{} = invitation,
        %OfferChallengeTeam{} = team,
        %User{} = current_user,
        %User{} = challenge_owner,
        attrs \\ %{}
      ) do
    %OfferChallengeTeamMembers{}
    |> OfferChallengeTeamMembers.changeset(invitation, team, current_user, challenge_owner, attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def get_team_member_accepted_invitation(%{team_id: team_id, status: status, email: email}) do
    from(
      invitation in OfferChallengeTeamInvitation,
      where:
        invitation.email == ^email and invitation.team_id == ^team_id and
          invitation.status == ^status
    )
    |> Repo.one()
  end

  def get_team_member_invitation_by_token(token) do
    from(
      invitation in OfferChallengeTeamInvitation,
      where: invitation.token == ^token
    )
    |> Repo.one()
  end

  def resend_team_member_invitation(
        %OfferChallengeTeamInvitation{} = team_invitation,
        %User{} = current_user,
        %User{} = challenge_owner
      ) do
    team_invitation
    |> OfferChallengeTeamInvitation.invitation_resent_changeset(current_user, challenge_owner)
    |> Repo.update()
  end

  def create_team_member_invitation(team, attrs \\ %{}) do
    %OfferChallengeTeamInvitation{}
    |> OfferChallengeTeamInvitation.changeset(team, attrs)
    |> Repo.insert()
  end

  def cancel_team_member_invitation(
        %OfferChallengeTeamInvitation{} = team_invitation,
        %User{} = current_user,
        %User{} = challenge_owner
      ) do
    team_invitation
    |> OfferChallengeTeamInvitation.invitation_cancelled_changeset(current_user, challenge_owner)
    |> Repo.update()
  end

  def accepted_team_member_invitation(%OfferChallengeTeamInvitation{} = team_invitation) do
    team_invitation
    |> OfferChallengeTeamInvitation.invitation_accepted_changeset()
    |> Repo.update()
  end

  def kick_team_member(
        team_member,
        %OfferChallenge{
          status: status,
          team: %{users: team_members} = team,
          user_id: challenge_owner_user_id
        },
        %User{id: logged_in_challenge_owner_id}
      ) do
    result =
      team_member
      |> validate_challenge_owner(challenge_owner_user_id, logged_in_challenge_owner_id)
      # is team member in challenge.team?
      |> validate_team_member(team_members)
      # is challenge status active?
      |> validate_challenge_status(status)

    case result do
      {:ok, struct} ->
        get_team_member_accepted_invitation(%{
          team_id: team.id,
          status: "accepted",
          email: team_member.user.email
        })
        |> Repo.delete()

        Repo.delete(struct)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_challenge_owner(
         team_member,
         challenge_owner_user_id,
         logged_in_challenge_owner_id
       ) do
    if challenge_owner_user_id != logged_in_challenge_owner_id do
      {:error, "Challenge owner is not correct!"}
    else
      {:ok, team_member}
    end
  end

  defp validate_team_member({:ok, team_member} = struct, team_members) do
    result = Enum.find(team_members, &(&1.id == team_member.user_id))

    if not is_nil(result) and result > 0 do
      struct
    else
      {:error, "team member not found in team!"}
    end
  end

  defp validate_team_member({:error, _reason} = struct, _team_members), do: struct

  defp validate_challenge_status({:ok, _team_member} = struct, status) do
    cond do
      status == "active" -> struct
      status == "pre_registration" -> struct
      status == "complete" -> {:error, "Cannot kick team member from complete challenge."}
      status == "expired" -> {:error, "Cannot kick team member from expired challenge."}
    end
  end

  defp validate_challenge_status({:error, _} = struct, _), do: struct

  def get_team_member(user_id, team_id) do
    from(
      otm in OfferChallengeTeamMembers,
      where: otm.user_id == ^user_id and otm.team_id == ^team_id,
      preload: [:user]
    )
    |> Repo.one()
  end

  def get_team!(id), do: Repo.get!(OfferChallengeTeam, id)

  def create_offer_challenge_activity_m2m(
        %ActivityAccumulator{} = activity,
        %OfferChallenge{} = challenge
      ),
      do: OfferChallengeActivitiesM2m.changeset(activity, challenge) |> Repo.insert()

  def number_of_completed_challenges_over_week(user_id) do
    today = Timex.now()
    one_week_ago = today |> Timex.shift(days: -7)

    from(o in OfferChallenge,
      where:
        o.status == "complete" and o.user_id == ^user_id and
          fragment("? BETWEEN ? and ?", o.updated_at, ^one_week_ago, ^today)
    )
    |> Repo.aggregate(:count, :id)
  end

  def number_of_rewards_redeemed_over_week(user_id) do
    today = Timex.now()
    one_week_ago = today |> Timex.shift(days: -7)

    from(r in OfferRedeem,
      where:
        r.status == "redeemed" and r.user_id == ^user_id and
          fragment("? BETWEEN ? and ?", r.updated_at, ^one_week_ago, ^today)
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  check if there is rewards expiring in the next 14 days for the given user
  """
  @spec expiring_reward(integer()) :: boolean()
  def expiring_reward(user_id) do
    from(r in OfferRedeem,
      where:
        r.user_id == ^user_id and r.status == "pending" and not is_nil(r.expired_at) and
          fragment("? BETWEEN now() AND now() + interval '14 days'", r.expired_at),
      select: count(r.id) > 0
    )
    |> Repo.one()
  end

  @doc """
  list all the offers within 50km of the given coordinate and check if the user can access or not
  """
  @spec list_offer_coordinates(integer(), Decimal.t(), Decimal.t()) :: [OfferGpsCoordinate.t()]
  def list_offer_coordinates(user_id, longitude, latitude) do
    geom = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}
    now = Timex.now()

    from(oc in OfferGpsCoordinate,
      as: :coordinate,
      left_join: offer in assoc(oc, :offer),
      left_lateral_join:
        open_offer in subquery(
          from(offer in Offer,
            left_join: op in assoc(offer, :offer_partners),
            where:
              offer.hidden == false and is_nil(op.id) and
                offer.id == parent_as(:coordinate).offer_id,
            select: %{offer_id: offer.id, can_access: is_nil(op.id)}
          )
        ),
      on: oc.offer_id == open_offer.offer_id,
      left_lateral_join:
        close_offer in subquery(
          from(
            offer in Offer,
            right_join: p in assoc(offer, :partners),
            right_join: m in assoc(p, :members),
            on: m.user_id == ^user_id,
            where: offer.id == parent_as(:coordinate).offer_id,
            select: %{offer_id: offer.id, can_access: not is_nil(m.id)}
          )
        ),
      on: oc.offer_id == close_offer.offer_id,
      where:
        st_dwithin_in_meters(oc.geom, ^geom, 50000) and offer.end_date > ^now and
          offer.approval_status == :approved,
      select: %{oc | can_access: coalesce(open_offer.can_access or close_offer.can_access, false)}
    )
    |> Repo.all()
  end

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(Offer, %{scope: :public_available}) do
    now = Timex.now()

    from(
      offer in Offer,
      where: offer.end_date > ^now and offer.approval_status == :approved,
      order_by: [desc: offer.id]
    )
  end

  def query(queryable, _), do: queryable
end
