defmodule OmegaBravera.Offers do
  @moduledoc """
  The Offers context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias OmegaBravera.Repo

  alias OmegaBravera.Offers.{
    Offer,
    OfferChallenge,
    OfferVendor,
    OfferChallengeTeamMembers,
    OfferChallengeTeamInvitation,
    OfferChallengeTeam,
    OfferRedeem,
    OfferChallengeActivitiesM2m
  }

  alias OmegaBravera.Points

  alias OmegaBravera.Activity.ActivityAccumulator
  alias OmegaBravera.Accounts.User

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

  @doc """
  Gets a single offer.

  Raises `Ecto.NoResultsError` if the Offer does not exist.

  ## Examples

      iex> get_offer!(123)
      %Offer{}

      iex> get_offer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer!(id), do: Repo.get!(Offer, id)

  def get_offer_by_slug(slug, preloads \\ [:offer_challenges]) do
    offer =
      from(o in Offer,
        where: o.slug == ^slug,
        left_join: offer_challenges in assoc(o, :offer_challenges),
        on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
        preload: ^preloads,
        group_by: [o.id],
        select: %{
          o
          | active_offer_challenges: count(offer_challenges.id),
            pre_registration_start_date:
              fragment("? at time zone 'utc'", o.pre_registration_start_date)
        }
      )
      |> Repo.one()

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
        select: %{
          oc
          | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance),
            start_date: fragment("? at time zone 'utc'", oc.start_date),
            end_date: fragment("? at time zone 'utc'", oc.end_date)
        }
      )

    Repo.one(query)
  end

  def get_offer_by_slug_with_hk_time(slug, preloads \\ [:offer_challenges]) do
    offer =
      from(o in Offer,
        where: o.slug == ^slug,
        left_join: offer_challenges in assoc(o, :offer_challenges),
        on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
        preload: ^preloads,
        group_by: [o.id],
        select: %{
          o
          | active_offer_challenges: count(offer_challenges.id),
            end_date: fragment("? at time zone 'utc' at time zone 'asia/hong_kong'", o.end_date),
            pre_registration_start_date:
              fragment(
                "? at time zone 'utc' at time zone 'asia/hong_kong'",
                o.pre_registration_start_date
              ),
            start_date:
              fragment("? at time zone 'utc' at time zone 'asia/hong_kong'", o.start_date),
            end_date: fragment("? at time zone 'utc' at time zone 'asia/hong_kong'", o.end_date)
        }
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
    |> switch_pre_registration_date_to_utc()
    |> switch_start_date_to_utc()
    |> switch_end_date_to_utc()
    |> Repo.insert()
  end

  defp switch_start_date_to_utc(
         %Ecto.Changeset{valid?: true, changes: %{start_date: start_date}} = changeset
       ),
       do: Ecto.Changeset.change(changeset, %{start_date: to_utc(start_date)})

  defp switch_start_date_to_utc(%Ecto.Changeset{} = changeset), do: changeset

  defp switch_end_date_to_utc(
         %Ecto.Changeset{valid?: true, changes: %{end_date: end_date}} = changeset
       ),
       do: Ecto.Changeset.change(changeset, %{end_date: to_utc(end_date)})

  defp switch_end_date_to_utc(%Ecto.Changeset{} = changeset), do: changeset

  defp switch_pre_registration_date_to_utc(
         %Ecto.Changeset{
           valid?: true,
           changes: %{pre_registration_start_date: pre_registration_start_date}
         } = changeset
       ),
       do:
         Ecto.Changeset.change(changeset, %{
           pre_registration_start_date: to_utc(pre_registration_start_date)
         })

  defp switch_pre_registration_date_to_utc(%Ecto.Changeset{} = changeset), do: changeset

  defp to_utc(%DateTime{} = datetime) do
    datetime
    |> Timex.to_datetime()
    |> DateTime.to_naive()
    |> Timex.to_datetime("Asia/Hong_Kong")
    |> Timex.to_datetime("Etc/UTC")
  end

  @doc """
  Updates a offer.

  ## Examples

      iex> update_offer(offer, %{field: new_value})
      {:ok, %Offer{}}

      iex> update_offer(offer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer(%Offer{} = offer, attrs) do
    offer
    |> Offer.changeset(attrs)
    |> switch_pre_registration_date_to_utc()
    |> switch_start_date_to_utc()
    |> switch_end_date_to_utc()
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

  def list_offers_preload(preloads \\ [:vendor]) do
    from(
      o in Offer,
      left_join: challenge in assoc(o, :offer_challenges),
      left_join: user in assoc(challenge, :user),
      preload: ^preloads,
      order_by: o.inserted_at,
      group_by: [o.id],
      select: %{o | unique_participants: count(user.id, :distinct)}
    )
    |> Repo.all()
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
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance),
          start_date: fragment("? at time zone 'utc'", oc.start_date),
          end_date: fragment("? at time zone 'utc'", oc.end_date)
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
    Repo.all(OfferReward)
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
  Returns the list of offer_vendors.

  ## Examples

      iex> list_offer_vendors()
      [%OfferVendor{}, ...]

  """
  def list_offer_vendors do
    Repo.all(OfferVendor)
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
  def get_offer_vendor!(id), do: Repo.get!(OfferVendor, id)

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

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(Offer, %{scope: :public_available}) do
    now = Timex.now("Asia/Hong_Kong")

    from(
      offer in Offer,
      where: offer.end_date > ^now,
      order_by: [desc: offer.id]
    )
  end

  def query(queryable, _), do: queryable
end
