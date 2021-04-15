defmodule OmegaBravera.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Ecto.Multi
  alias Absinthe.Relay
  alias OmegaBravera.Accounts.Jobs
  @organization_max_points 1000

  alias OmegaBravera.{
    Repo,
    Accounts,
    Accounts.Credential,
    Accounts.Donor,
    Accounts.Notifier,
    Accounts.PartnerUser,
    Accounts.Tools,
    Accounts.User,
    Accounts.AdminUser,
    Devices.Device,
    Money.Donation,
    Trackers,
    Points.Point,
    Trackers.Strava,
    Challenges.NGOChal,
    Challenges.Team,
    Challenges.TeamMembers,
    Money.Donation,
    Offers.OfferChallenge,
    Offers.OfferChallengeTeam,
    Offers.OfferChallengeTeamMembers,
    Offers.OfferRedeem,
    Offers.OfferChallengeActivitiesM2m,
    Activity.ActivityAccumulator,
    Groups.Member,
    Accounts.Organization,
    Accounts.OrganizationMember,
    Accounts.Friend,
    Accounts.PrivateChatMessage
  }

  def get_all_athlete_ids() do
    query = from(s in Strava, select: s.athlete_id)
    query |> Repo.all()
  end

  def user_has_device?(user_id) do
    devices = from(d in Device, where: d.user_id == ^user_id) |> Repo.all() |> length()
    if devices > 0, do: true, else: false
  end

  def get_all_user_ids do
    from(u in User, select: u.id, where: not is_nil(u.email))
    |> Repo.all()
  end

  def get_user_by_athlete_id(athlete_id) do
    from(u in User,
      join: s in Strava,
      on: s.athlete_id == ^athlete_id,
      where: u.id == s.user_id
    )
    |> Repo.one()
  end

  def get_num_of_segment_challenges_by_user_id(user_id) do
    from(
      oc in OfferChallenge,
      where: oc.id == ^user_id,
      where: oc.status == "active",
      where: oc.type == "BRAVERA_SEGMENT",
      select: count(oc.id)
    )
    |> Repo.one()
  end

  def get_strava_by_athlete_id(athlete_id) do
    from(s in Strava, where: s.athlete_id == ^athlete_id) |> Repo.one()
  end

  def get_strava_challengers(athlete_id) do
    team_challengers =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: nc in NGOChal,
        where: nc.status == "active",
        join: t in Team,
        on: nc.id == t.challenge_id,
        join: tm in TeamMembers,
        on: t.id == tm.team_id,
        where: tm.user_id == s.user_id,
        join: u in User,
        on: s.user_id == u.id,
        select: {
          nc.id,
          u,
          s.token
        }
      )
      |> Repo.all()

    single_challengers =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: nc in NGOChal,
        where: s.user_id == nc.user_id and nc.status == "active",
        join: u in User,
        on: s.user_id == u.id,
        select: {
          nc.id,
          u,
          s.token
        }
      )
      |> Repo.all()

    team_challengers ++ single_challengers
  end

  def get_strava_challengers_for_offers(athlete_id) do
    team_challengers =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: oc in OfferChallenge,
        where: oc.status == "active",
        join: t in OfferChallengeTeam,
        on: oc.id == t.offer_challenge_id,
        join: tm in OfferChallengeTeamMembers,
        on: t.id == tm.team_id,
        where: tm.user_id == s.user_id,
        join: u in User,
        on: s.user_id == u.id,
        select: {
          oc.id,
          u,
          s.token
        }
      )
      |> Repo.all()

    single_challengers =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: oc in OfferChallenge,
        where: s.user_id == oc.user_id and oc.status == "active",
        join: u in User,
        on: s.user_id == u.id,
        select: {
          oc.id,
          u,
          s.token
        }
      )
      |> Repo.all()

    team_challengers ++ single_challengers
  end

  def get_challenges_for_offers(user_id) do
    from(u in User,
      where: u.id == ^user_id,
      join: oc in OfferChallenge,
      where: oc.status == "active" and oc.user_id == ^user_id,
      select: {
        oc.id,
        u
      }
    )
    |> Repo.all()
  end

  defp donors_for_challenge_query(challenge) do
    from(donor in Donor,
      join: donation in Donation,
      on: donation.donor_id == donor.id,
      where: donation.ngo_chal_id == ^challenge.id,
      distinct: donation.donor_id,
      order_by: donor.id
    )
  end

  def donors_for_challenge(%NGOChal{} = challenge) do
    challenge
    |> donors_for_challenge_query()
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def latest_donors(%NGOChal{type: "PER_MILESTONE"} = challenge, limit \\ nil) do
    query =
      challenge
      |> donors_for_challenge_query()
      |> order_by(desc: :inserted_at)
      |> group_by([donor, donation], [donor.id, donation.donor_id, donation.currency])
      |> select([donor, donation], {donor, sum(donation.amount), donation.currency})

    query =
      if is_number(limit) and limit > 0 do
        limit(query, ^limit)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.map(fn {donor, amount, currency} ->
      %{"user" => donor, "pledged" => amount, "currency" => currency}
    end)
  end

  def latest_km_donors(%NGOChal{type: "PER_KM"} = challenge, limit \\ nil) do
    query =
      challenge
      |> donors_for_challenge_query()
      |> order_by(desc: :inserted_at)
      |> group_by([donor, donation], [
        donor.id,
        donation.donor_id,
        donation.currency,
        donation.type
      ])
      |> select(
        [donor, donation],
        {donor, donation.type, sum(donation.amount), donation.currency}
      )

    query =
      if is_number(limit) and limit > 0 do
        limit(query, ^limit)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.map(fn {donor, donation_type, amount, currency} ->
      case donation_type do
        "follow_on" ->
          follow_on_donation_result(donor, amount, currency)

        _ ->
          km_donation_result(donor, amount, challenge, currency)
      end
    end)
  end

  defp km_donation_result(donor, amount, challenge, currency) do
    %{
      "user" => donor,
      "pledged" => Decimal.mult(amount, challenge.distance_target),
      "currency" => currency
    }
  end

  defp follow_on_donation_result(donor, amount, currency) do
    %{
      "user" => donor,
      "pledged" => amount,
      "currency" => currency
    }
  end

  # TODO Optimize the preload below
  def get_user_strava(user_id) do
    from(s in Strava, where: s.user_id == ^user_id)
    |> Repo.one()
  end

  def get_user_with_everything!(user_id) do
    user = User

    user
    |> where([user], user.id == ^user_id)
    |> join(:left, [user], ngo_chals in assoc(user, :ngo_chals))
    |> join(:left, [user, ngo_chals], donations in assoc(ngo_chals, :donations))
    |> preload([user, ngo_chals, donations, offer_teams, team_offer_challenge],
      ngo_chals: {ngo_chals, donations: donations}
    )
    |> Repo.one()
    |> Repo.preload([
      :strava,
      :setting,
      :credential,
      offer_challenges: [:offer_redeems],
      offer_teams: [:offer_challenge]
    ])
  end

  def get_user_with_active_challenges(user_id) do
    from(
      u in User,
      where: u.id == ^user_id,
      left_join: oc in OfferChallenge,
      on: oc.user_id == u.id and oc.status == ^"active",
      preload: [offer_challenges: oc]
    )
    |> Repo.one()
  end

  def get_user_with_points(user_id) do
    user =
      from(u in User,
        where: u.id == ^user_id,
        left_join: p in Point,
        on: p.user_id == u.id,
        group_by: [u.id],
        select: %{u | total_points: sum(p.value)}
      )
      |> Repo.one()

    if is_nil(user.total_points) do
      %{user | total_points: Decimal.new(0)}
    else
      user
    end
  end

  defp point_query do
    from(p in Point, select: %{value: sum(p.value), user_id: p.user_id}, group_by: p.user_id)
  end

  defp activity_query(start_date, end_date) do
    from(a in ActivityAccumulator,
      select: %{distance: coalesce(sum(a.distance), 0), user_id: a.user_id},
      group_by: a.user_id,
      where:
        a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
          not is_nil(a.device_id) and is_nil(a.strava_id) and a.start_date >= ^start_date and
          a.start_date <= ^end_date
    )
  end

  defp activity_query do
    from(a in ActivityAccumulator,
      select: %{distance: sum(a.distance), user_id: a.user_id},
      group_by: a.user_id,
      where:
        a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
          not is_nil(a.device_id) and is_nil(a.strava_id)
    )
  end

  def api_get_leaderboard_this_week() do
    now = Timex.now()
    beginning = Timex.beginning_of_week(now)
    end_of_week = Timex.end_of_week(now)

    from(
      u in User,
      left_join: a in subquery(activity_query(beginning, end_of_week)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      select: %{
        u
        | total_points_this_week: coalesce(p.value, 0),
          total_kilometers_this_week: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  def api_get_leaderboard_this_month() do
    now = Timex.now()
    beginning = Timex.beginning_of_month(now)
    end_of_month = Timex.end_of_month(now)

    from(
      u in User,
      left_join: a in subquery(activity_query(beginning, end_of_month)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      select: %{
        u
        | total_points_this_month: coalesce(p.value, 0),
          total_kilometers_this_month: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  def api_get_leaderboard_all_time() do
    from(
      u in User,
      left_join: a in subquery(activity_query()),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      select: %{
        u
        | total_points: coalesce(p.value, 0),
          total_kilometers: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  defp members(partner_id) do
    from(m in Member, where: m.partner_id == ^partner_id, select: m.user_id)
    |> Repo.all()
  end

  def api_get_leaderboard_of_partner_this_week(partner_id) do
    now = Timex.now()
    beginning = Timex.beginning_of_week(now)
    end_of_week = Timex.end_of_week(now)

    from(
      u in User,
      left_join: a in subquery(activity_query(beginning, end_of_week)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      where: u.id in ^members(partner_id),
      select: %{
        u
        | total_points_this_week: coalesce(p.value, 0),
          total_kilometers_this_week: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  def api_get_leaderboard_of_partner_this_month(partner_id) do
    now = Timex.now()
    beginning = Timex.beginning_of_month(now)
    end_of_month = Timex.end_of_month(now)

    from(
      u in User,
      left_join: a in subquery(activity_query(beginning, end_of_month)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      where: u.id in ^members(partner_id),
      select: %{
        u
        | total_points_this_month: coalesce(p.value, 0),
          total_kilometers_this_month: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  def api_get_leaderboard_of_partner_all_time(partner_id) do
    from(
      u in User,
      left_join: a in subquery(activity_query()),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      preload: [:strava],
      where: u.id in ^members(partner_id),
      select: %{
        u
        | total_points: coalesce(p.value, 0),
          total_kilometers: coalesce(a.distance, 0)
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  def user_live_challenges(user_id) do
    from(oc in OfferChallenge,
      where:
        (oc.status == "active" or oc.status == "pre_registration") and oc.user_id == ^user_id,
      left_join: a in OfferChallengeActivitiesM2m,
      on: oc.id == a.offer_challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      group_by: oc.id,
      order_by: [desc: :inserted_at],
      preload: [:offer],
      select: %{
        oc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 2)", ac.distance)
      }
    )
    |> Repo.all()
  end

  def future_redeems(user_id),
    do:
      from(
        ofr in OfferRedeem,
        left_join: oc in assoc(ofr, :offer_challenge),
        left_join: o in assoc(oc, :offer),
        where: ofr.user_id == ^user_id and ofr.status == ^"pending" and oc.status == ^"complete",
        order_by: [desc: :inserted_at],
        select: %{
          ofr
          | online_url: o.online_url,
            token:
              fragment(
                "CASE WHEN ? = 'online' THEN ? ELSE ? END",
                o.offer_type,
                o.online_code,
                ofr.token
              )
        }
      )
      |> Repo.all()

  def past_redeems(user_id),
    do:
      from(
        ofr in OfferRedeem,
        where: ofr.user_id == ^user_id and ofr.status == ^"redeemed",
        order_by: [desc: :updated_at]
      )
      |> Repo.all()

  def expired_challenges(user_id),
    do:
      from(oc in OfferChallenge,
        where: oc.status == "expired" and oc.user_id == ^user_id,
        left_join: a in OfferChallengeActivitiesM2m,
        on: oc.id == a.offer_challenge_id,
        left_join: ac in ActivityAccumulator,
        on: a.activity_id == ac.id,
        order_by: [desc: :end_date],
        group_by: oc.id,
        select: %{
          oc
          | distance_covered: fragment("round(sum(coalesce(?, 0)), 2)", ac.distance)
        }
      )
      |> Repo.all()

  def api_user_profile(user_id) do
    total_rewards =
      Repo.aggregate(
        from(ofr in OfferRedeem, where: ofr.status == "redeemed" and ofr.user_id == ^user_id),
        :count,
        :id
      )

    total_kms_offers =
      Repo.aggregate(
        from(
          a in ActivityAccumulator,
          where: a.user_id == ^user_id,
          where: not is_nil(a.device_id) and is_nil(a.strava_id)
        ),
        :sum,
        :distance
      )

    total_kms_offers =
      if is_nil(total_kms_offers),
        do: Decimal.from_float(0.0),
        else: total_kms_offers

    live_challenges = user_live_challenges(user_id)

    expired_challenges = expired_challenges(user_id)

    completed_challenges =
      from(oc in OfferChallenge,
        where: oc.status == "complete" and oc.user_id == ^user_id,
        left_join: a in OfferChallengeActivitiesM2m,
        on: oc.id == a.offer_challenge_id,
        left_join: ac in ActivityAccumulator,
        on: a.activity_id == ac.id,
        group_by: oc.id,
        order_by: [desc: :updated_at],
        select: %{
          oc
          | distance_covered: fragment("round(sum(coalesce(?, 0)), 2)", ac.distance)
        }
      )
      |> Repo.all()

    user =
      from(
        u in User,
        where: u.id == ^user_id,
        preload: [:strava]
      )
      |> Repo.one()

    %{
      user
      | total_rewards: total_rewards,
        total_kilometers: total_kms_offers,
        offer_challenges_map: %{
          live: live_challenges,
          expired: expired_challenges,
          completed: completed_challenges,
          total:
            list_length(live_challenges) + list_length(expired_challenges) +
              list_length(completed_challenges)
        }
    }
  end

  defp list_length(list) when is_nil(list) == true, do: 0
  defp list_length(list), do: length(list)

  def preload_active_offer_challenges(user) do
    user
    |> Repo.preload(
      offer_challenges:
        from(oc in OfferChallenge,
          left_join: ofr in assoc(oc, :offer_redeems),
          where:
            oc.status in ["active", "pre_registration"] or
              (oc.status == "complete" and ofr.status == "pending")
        )
    )
  end

  def get_user_by_token(token) do
    from(u in User, where: u.email_activation_token == ^token) |> Repo.one()
  end

  def insert_or_update_strava_user(%{athlete_id: nil}), do: {:error, "No athlete id!"}

  def insert_or_update_strava_user(changeset) do
    case Trackers.get_strava_with_athlete_id(changeset[:athlete_id]) do
      nil ->
        Accounts.Strava.create_user_with_tracker(changeset)

      strava ->
        updated_user =
          case Accounts.update_user(strava.user, changeset) do
            {:ok, u} -> u
            {:error, _} -> strava.user
          end

        Trackers.create_or_update_tracker(updated_user, changeset)
        {:ok, updated_user}
    end
  end

  @doc """
    Creates User with a credential
  """

  # TODO: work on replacing this with a cast_assoc one -Sherief
  def create_credentialed_user(%{
        "user" => %{
          "email" => email,
          "password" => password,
          "password_confirmation" => password_confirmation
        }
      }) do
    Multi.new()
    |> Multi.run(:user, fn %{} -> create_user(%{"email" => email}) end)
    |> Multi.run(:credential, fn %{user: %{id: user_id}} ->
      create_credential(user_id, %{
        "password" => password,
        "password_confirmation" => password_confirmation
      })
    end)
    |> Repo.transaction()
  end

  @doc """
    Looks for credential based on user email
  """

  def get_user_credential(email) do
    #  there used to be credential = here, don't think it is used
    case email do
      nil ->
        nil

      email ->
        case Repo.get_by(User, email: email) do
          %{id: user_id} ->
            from(c in Credential,
              where: c.user_id == ^user_id
            )
            |> Repo.one()

          nil ->
            nil
        end
    end
  end

  @doc """
    Looks for credential based on reset token
  """

  def get_credential_by_token(token, preloads \\ [:user]) do
    from(c in Credential,
      where: c.reset_token == ^token,
      preload: ^preloads
    )
    |> Repo.one()
  end

  @doc """
    Inserts or returns an email user (if email is not already registered, insert it)
  """
  def insert_or_return_email_user(%{"email" => email, "first_name" => first, "last_name" => last}) do
    case Repo.get_by(User, email: email) do
      nil ->
        case create_user(%{"email" => email, "firstname" => first, "lastname" => last}) do
          {:ok, user} -> user
          {:error, _reason} -> nil
        end

      user ->
        user
    end
  end

  def insert_or_return_email_donor(%{"email" => email, "first_name" => first, "last_name" => last}) do
    case Repo.get_by(Donor, email: email) do
      nil ->
        case create_donor(%{"email" => email, "firstname" => first, "lastname" => last}) do
          {:ok, donor} -> donor
          {:error, _reason} -> nil
        end

      donor ->
        donor
    end
  end

  @doc """
  Functions for password-based user credentials
  """

  def email_password_auth(email, password) when is_binary(email) and is_binary(password) do
    with {:ok, user} <- get_by_email(email),
         do: verify_password(password, user)
  end

  defp get_by_email(email) when is_binary(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        dummy_checkpw()
        {:error, :user_does_not_exist}

      user ->
        {:ok, user}
    end
  end

  defp verify_password(password, user) when is_binary(password) do
    query =
      from(c in Credential,
        where: c.user_id == ^user.id
      )

    credential = Repo.one(query)

    cond do
      credential != nil ->
        if checkpw(password, credential.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_password}
        end

      credential == nil ->
        {:error, :no_credential}
    end
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    from(u in User, order_by: [desc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Generates data for the dashboard.
  """
  @spec organization_dashboard(String.t()) :: map()
  def organization_dashboard(organization_id) do
    now = Timex.now()
    beginning_of_week = Timex.beginning_of_week(now)
    end_of_week = Timex.end_of_week(now)
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)

    # Need to run in separate query or else
    # query will be VERY long running.
    members =
      from(o in Organization,
        left_join: m in assoc(o, :group_members),
        where: o.id == ^organization_id,
        group_by: o.id,
        select: fragment("TO_CHAR(?, '999,999')", count(m.user_id, :distinct))
      )
      |> Repo.one()

    from(o in Organization,
      as: :org,
      where: o.id == ^organization_id,
      left_join: g in assoc(o, :groups),
      left_join: of in assoc(o, :offers),
      #      left_lateral_join:
      #        m in subquery(
      #          from(o in OmegaBravera.Groups.Member,
      #            left_join: m in assoc(:group_members),
      #            where: o.id == parent_as(:org).id
      #          )
      #        ),
      #      on: m.organization_id == o.id,
      left_lateral_join:
        td in subquery(
          from(a in OmegaBravera.Activity.ActivityAccumulator,
            left_join: u in OmegaBravera.Groups.Member,
            on: u.user_id == a.user_id,
            left_join: g in assoc(u, :partner),
            where:
              g.organization_id == parent_as(:org).id and is_nil(a.strava_id) and
                not is_nil(a.device_id),
            group_by: g.organization_id,
            select: %{distance: coalesce(sum(a.distance), 0), organization_id: g.organization_id}
          )
        ),
      on: td.organization_id == o.id,
      left_lateral_join:
        wd in subquery(
          from(a in OmegaBravera.Activity.ActivityAccumulator,
            left_join: u in OmegaBravera.Groups.Member,
            on: u.user_id == a.user_id,
            left_join: g in assoc(u, :partner),
            where:
              g.organization_id == ^organization_id and is_nil(a.strava_id) and
                not is_nil(a.device_id) and a.start_date >= ^beginning_of_week and
                a.end_date <= ^end_of_week,
            group_by: g.organization_id,
            select: %{distance: coalesce(sum(a.distance), 0), organization_id: g.organization_id}
          )
        ),
      on: wd.organization_id == o.id,
      left_join: oc in assoc(of, :offer_challenges),
      left_join: ofr in assoc(oc, :offer_redeems),
      left_lateral_join:
        p in subquery(
          from p in OmegaBravera.Points.Point,
            group_by: p.organization_id,
            where:
              p.organization_id == parent_as(:org).id and p.inserted_at >= ^beginning_of_day and
                p.inserted_at <= ^end_of_day,
            select: %{
              organization_id: p.organization_id,
              points: coalesce(sum(fragment("ABS(?)", p.value)), 0)
            }
        ),
      on: p.organization_id == o.id,
      group_by: [o.id, td.distance, wd.distance, p.points],
      select: %{
        groups: fragment("TO_CHAR(?, '999,999')", count(g.id, :distinct)),
        offers: fragment("TO_CHAR(?, '999,999')", count(of.id, :distinct)),
        total_distance: fragment("TO_CHAR(?, '999,999 KM')", td.distance),
        distance_this_week: fragment("TO_CHAR(?, '999,999 KM')", wd.distance),
        unlocked_rewards:
          fragment(
            "TO_CHAR(?, '999,999')",
            filter(count(oc.id, :distinct), oc.status == "complete")
          ),
        claimed_rewards:
          fragment(
            "TO_CHAR(?, '999,999')",
            filter(count(ofr.id, :distinct), ofr.status == "redeemed")
          ),
        remaining_points:
          fragment("TO_CHAR(?, '999,999')", @organization_max_points - coalesce(p.points, 0))
      }
    )
    |> Repo.one()
    |> Map.put(:members, members)
  end

  @doc """
  Generate admin dashboard
  """
  def admin_dashboard_users_info() do
    from(u in User,
      as: :user,
      left_lateral_join:
        aa_month in subquery(
          from(aa in OmegaBravera.Activity.ActivityAccumulator,
            where:
              aa.user_id == parent_as(:user).id and
                fragment("? BETWEEN now() - interval '30 days' and now()", aa.end_date) and
                not is_nil(aa.device_id) and is_nil(aa.strava_id),
            limit: 1,
            select: [:id, :user_id]
          )
        ),
      on: aa_month.user_id == u.id,
      left_lateral_join:
        aa_total in subquery(
          from(aa in OmegaBravera.Activity.ActivityAccumulator,
            group_by: aa.user_id,
            where: not is_nil(aa.device_id) and is_nil(aa.strava_id),
            select: %{distance: coalesce(sum(aa.distance), 0), user_id: aa.user_id}
          )
        ),
      on: aa_total.user_id == u.id,
      left_lateral_join:
        aa_week in subquery(
          from(aa in OmegaBravera.Activity.ActivityAccumulator,
            where:
              fragment("? BETWEEN now() - interval '7 days' and now()", aa.end_date) and
                not is_nil(aa.device_id) and is_nil(aa.strava_id),
            group_by: aa.user_id,
            select: %{distance: coalesce(sum(aa.distance), 0), user_id: aa.user_id}
          )
        ),
      on: aa_week.user_id == u.id,
      left_join: setting in assoc(u, :setting),
      left_join: device in assoc(u, :devices),
      on: device.active == true,
      select: %{
        total_users: fragment("TO_CHAR(?, '999,999,999')", count(u.id)),
        new_users:
          fragment(
            "TO_CHAR(?, '999,999,999')",
            filter(
              count(u.id),
              fragment(
                "? BETWEEN date_trunc('month', now()) AND date_trunc('month', now()) + interval '1 month'",
                u.inserted_at
              )
            )
          ),
        active_users: fragment("TO_CHAR(?, '999,999,999')", count(aa_month.user_id)),
        total_referrals: fragment("TO_CHAR(?, '999,999,999')", count(u.referred_by_id)),
        new_referrals:
          fragment(
            "TO_CHAR(?, '999,999,999')",
            filter(
              count(u.referred_by_id),
              fragment(
                "? BETWEEN date_trunc('month', now()) AND date_trunc('month', now()) + interval '1 month'",
                u.inserted_at
              )
            )
          ),
        total_distance: fragment("TO_CHAR(?, '999,999,999,999.99 KM')", sum(aa_total.distance)),
        weekly_distance:
          fragment("TO_CHAR(?, '999,999,999.99 KM')", coalesce(sum(aa_week.distance), 0)),
        female:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(u.id), setting.gender == "Female")),
        male:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(u.id), setting.gender == "Male")),
        other_gender:
          fragment(
            "TO_CHAR(?, '999,999,999')",
            filter(count(u.id), setting.gender != "Female" and setting.gender != "Male")
          ),
        ios_users:
          fragment("TO_CHAR(?, '999,999,999')", filter(count(u.id), ilike(device.uuid, "%-%"))),
        android_users:
          fragment(
            "TO_CHAR(?, '999,999,999')",
            filter(count(u.id), not ilike(device.uuid, "%-%") and not is_nil(device.uuid))
          )
      }
    )
    |> Repo.one()
  end

  @doc """
  Returns total number of points for the current day
  """
  @spec get_remaining_points_for_today_for_organization(String.t()) :: integer()
  def get_remaining_points_for_today_for_organization(organization_id) do
    now = Timex.now()
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)

    from(o in Organization,
      where: o.id == ^organization_id,
      left_join: p in assoc(o, :points),
      select:
        fragment(
          "TO_CHAR(?, '999,999')",
          ^@organization_max_points -
            coalesce(
              filter(
                sum(fragment("ABS(?)", p.value)),
                p.inserted_at >= ^beginning_of_day and p.inserted_at <= ^end_of_day
              ),
              0
            )
        )
    )
    |> Repo.one()
  end

  @spec list_users_for_org(String.t()) :: [User.t()]
  def list_users_for_org(organization_id) do
    from(u in User,
      left_join: m in OmegaBravera.Groups.Member,
      on: u.id == m.user_id,
      left_join: p in assoc(m, :partner),
      where: p.organization_id == ^organization_id,
      group_by: [u.id],
      order_by: [desc: u.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Prepares a list of current users with settings and extra fields ready in admin panel.
  """
  def list_users_for_admin_query() do
    today = Timex.today()
    before = today |> Timex.shift(days: -30)
    beginning_of_week = Timex.beginning_of_week(today)
    end_of_week = Timex.end_of_week(today)

    rewards_query =
      from(u in User,
        left_join: r in OmegaBravera.Offers.OfferRedeem,
        on: u.id == r.user_id,
        windows: [user_id: [partition_by: u.id]],
        distinct: true,
        left_join: oc in assoc(r, :offer_challenge),
        on: oc.status == ^"complete",
        select: %{user_id: u.id, count: coalesce(over(count(r.id), :user_id), 0)}
      )

    rewards_redeemed_query =
      from(u in User,
        left_join: r in OmegaBravera.Offers.OfferRedeem,
        on: u.id == r.user_id and r.status == "redeemed",
        windows: [user_id: [partition_by: u.id]],
        distinct: true,
        select: %{user_id: u.id, count: coalesce(over(count(r.id), :user_id), 0)}
      )

    total_distance_query =
      from(a in OmegaBravera.Activity.ActivityAccumulator,
        windows: [user_id: [partition_by: a.user_id]],
        distinct: true,
        select: %{user_id: a.user_id, sum: coalesce(over(sum(a.distance), :user_id), 0.0)}
      )

    weekly_distance_query =
      from(u in User,
        windows: [user_id: [partition_by: u.id]],
        distinct: true,
        left_join: a in OmegaBravera.Activity.ActivityAccumulator,
        on:
          u.id == a.user_id and
            fragment("?::DATE BETWEEN ? AND ?", a.start_date, ^beginning_of_week, ^end_of_week),
        select: %{user_id: u.id, sum: coalesce(over(sum(a.distance), :user_id), 0.0)}
      )

    friend_referrals_query =
      from(u in User,
        left_join: r in User,
        on: u.id == r.referred_by_id,
        windows: [user_id: [partition_by: u.id]],
        distinct: true,
        select: %{user_id: u.id, count: coalesce(over(count(r.id), :user_id), 0)}
      )

    from(u in User,
      order_by: [desc: u.inserted_at],
      preload: [:setting, :location],
      left_join: a in assoc(u, :activities),
      on: fragment("?::date BETWEEN ? AND ?", a.start_date, ^before, ^today),
      left_join: d in assoc(u, :devices),
      on: d.active == true,
      left_join: cr in subquery(rewards_redeemed_query),
      on: cr.user_id == u.id,
      left_join: r in subquery(rewards_query),
      on: r.user_id == u.id,
      left_join: td in subquery(total_distance_query),
      on: td.user_id == u.id,
      left_join: wtd in subquery(weekly_distance_query),
      on: wtd.user_id == u.id,
      left_join: fr in subquery(friend_referrals_query),
      on: fr.user_id == u.id,
      select: %{
        u
        | active: fragment("? > 0", count(a.id)),
          device_type:
            fragment(
              "CASE WHEN ? ILIKE '%-%' THEN 'iOS' WHEN ? IS NOT NULL THEN 'Android' ELSE '' END",
              d.uuid,
              d.uuid
            ),
          number_of_claimed_rewards: cr.count,
          number_of_rewards: r.count,
          total_kilometers: td.sum,
          total_kilometers_this_week: wtd.sum,
          friend_referrals: fr.count
      },
      group_by: [u.id, d.uuid, r.count, cr.count, td.sum, wtd.sum, fr.count]
    )
  end

  def list_users_for_admin do
    list_users_for_admin_query()
    |> Repo.all()
  end

  @doc """
  paginate users based on login user type
  """
  def paginate_users(%AdminUser{}, params) do
    Turbo.Ecto.turbo(list_users_for_admin_query(), params, entry_name: "users")
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, preloads \\ []), do: Repo.get!(User, id) |> Repo.preload(preloads)

  @doc """
  Gets a user by their email address.
  """
  def get_user_by_email!(email), do: from(u in User, where: u.email == ^email) |> Repo.one!()

  def get_user_with_account_settings(id) do
    Repo.get(User, id)
    |> Repo.preload([
      :credential,
      setting:
        from(s in Accounts.Setting,
          select: %{
            s
            | weight_fraction:
                fragment(
                  "case when ? is not null then mod(?, 1) else 0.0 end",
                  s.weight,
                  s.weight
                ),
              weight_whole:
                fragment(
                  "case when ? is not null then trunc(?)::integer else null end",
                  s.weight,
                  s.weight
                )
          }
        )
    ])
  end

  def get_user_with_todays_points(%User{id: user_id}, start_date \\ Timex.now()) do
    now = start_date

    user =
      from(
        u in User,
        where: u.id == ^user_id,
        left_join: p in Point,
        on:
          p.user_id == ^user_id and p.inserted_at >= ^Timex.beginning_of_day(now) and
            p.inserted_at <= ^Timex.end_of_day(now),
        group_by: u.id,
        select: %{u | todays_points: sum(p.value)}
      )
      |> Repo.one!()

    if is_nil(user.todays_points) do
      %{user | todays_points: 0}
    else
      user
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_credential_user(attrs \\ %{credential: %{}}, referral \\ nil) do
    result =
      %User{}
      |> User.create_credential_user_changeset(attrs, referral)
      |> Repo.insert()

    case result do
      {:ok, %{id: user_id}} = result ->
        now_hk = Timex.now("Asia/Hong_Kong")

        next_day =
          now_hk
          |> Timex.shift(days: 1)
          |> Timex.set(hour: 8, minute: 0, second: 0)
          |> Timex.Timezone.convert(:utc)

        seven_days =
          now_hk
          |> Timex.shift(days: 7)
          |> Timex.Timezone.convert(:utc)

        %{user_id: user_id}
        |> Jobs.NoActivityAfterSignup.new(scheduled_at: next_day)
        |> Oban.insert()

        %{user_id: user_id}
        |> Jobs.OneWeekNoActivityAfterSignup.new(scheduled_at: seven_days)
        |> Oban.insert()

        result

      result ->
        result
    end
  end

  def create_credential_for_existing_strava(attrs \\ %{}) do
    Credential.create_credential_for_strava_user(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Enables/disables global push notifications to all of the user's registered devices.
  """
  def enable_push_notifications(%User{} = user, attrs) do
    user
    |> User.push_notifications_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Activates a user's account by setting the user's `email_verified` field to true.
  """
  def activate_user_email(%User{} = user) do
    case update_user(user, %{email_verified: true}) do
      {:ok, _user} = return_tuple ->
        %{user_id: user.id}
        |> Jobs.AfterEmailVerify.new()
        |> Oban.insert()

        return_tuple

      other ->
        other
    end
  end

  def update_user_by_admin(%User{} = user, attrs) do
    user
    |> User.admin_update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def delete_user_profile_pictures(user) do
    user = Repo.preload(user, :strava)

    status =
      user
      |> User.delete_profile_picture_changeset()
      |> Repo.update()
      |> case do
        {:ok, _} -> true
        {:error} -> false
      end

    strava_status =
      if not is_nil(user.strava) do
        user.strava
        |> Strava.delete_strava_profile_picture_changeset()
        |> Repo.update()
        |> case do
          {:ok, _} -> true
          {:error} -> false
        end
      else
        true
      end

    status and strava_status
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def change_credential_user(%User{} = user, attrs \\ %{credential: %{}}) do
    User.create_credential_user_changeset(user, attrs)
  end

  def amount_of_current_users() do
    from(u in User, where: not is_nil(u.additional_info), select: count(u.id))
    |> Repo.one()
  end

  def new_user_this_month() do
    now = Timex.now()
    start_of_month = now |> Timex.beginning_of_month()
    end_of_month = now |> Timex.end_of_month()

    from(u in User,
      where:
        not is_nil(u.additional_info) and
          fragment("? BETWEEN ? and ?", u.inserted_at, ^start_of_month, ^end_of_month),
      select: count(u.id)
    )
    |> Repo.one()
  end

  def distance_sum(distance_list) do
    case distance_list do
      [] ->
        0

      _ ->
        %{sum: sum} =
          Enum.reduce(distance_list, fn item, acc ->
            %{sum: item.sum + acc.sum}
          end)

        round(sum)
    end
  end

  def total_distance_query() do
    from(a in OmegaBravera.Activity.ActivityAccumulator,
      group_by: [a.user_id],
      select: %{sum: sum(coalesce(a.distance, 0.0))}
    )
  end

  def total_distance() do
    total_distance_query()
    |> Repo.all()
    |> distance_sum()
  end

  defp amount_of_user_in_gender_query(gender) do
    from(u in User,
      left_join: s in assoc(u, :setting),
      where: not is_nil(u.additional_info) and s.gender == ^gender,
      select: count(u.id)
    )
  end

  def amount_of_male_users() do
    amount_of_user_in_gender_query("Male")
    |> Repo.one()
  end

  def amount_of_female_users() do
    amount_of_user_in_gender_query("Female")
    |> Repo.one()
  end

  def amount_of_other_users() do
    amount_of_user_in_gender_query("Other")
    |> Repo.one()
  end

  def amount_of_ios_users() do
    from(u in User,
      left_join: d in assoc(u, :devices),
      on: d.active == true,
      where: ilike(d.uuid, "%-%"),
      select: count(u.id)
    )
    |> Repo.one()
  end

  def amount_of_android_users() do
    from(u in User,
      left_join: d in assoc(u, :devices),
      on: d.active == true,
      where: not ilike(d.uuid, "%-%") and not is_nil(d.uuid),
      select: count(u.id)
    )
    |> Repo.one()
  end

  def number_of_referrals_over_week(user_id) do
    today = Timex.now()
    one_week_ago = today |> Timex.shift(days: -7)

    from(u in User,
      where:
        u.referred_by_id == ^user_id and
          fragment("? BETWEEN ? and ?", u.inserted_at, ^one_week_ago, ^today)
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single credential.

  Raises `Ecto.NoResultsError` if the Credential does not exist.

  ## Examples

      iex> get_credential!(123)
      %Credential{}

      iex> get_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credential!(id), do: Repo.get!(Credential, id)

  @doc """
  Creates a credential.

  ## Examples

      iex> create_credential(%{field: value})
      {:ok, %Credential{}}

      iex> create_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credential(user_id, attrs \\ %{}) do
    %Credential{user_id: user_id}
    |> Credential.changeset(attrs)
    |> Repo.insert()
  end

  # Check to see if email is taken by User
  # If not, create User and create Associated Credential (passwords)

  @doc """
  Updates a credential.

  ## Examples

      iex> update_credential(credential, %{field: new_value})
      {:ok, %Credential{}}

      iex> update_credential(credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_credential(%Credential{} = credential, attrs) do
    credential
    |> Credential.changeset(attrs)
    |> Repo.update()
  end

  def update_credential_token(%Credential{} = credential, attrs) do
    credential
    |> Credential.token_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Credential.

  ## Examples

      iex> delete_credential(credential)
      {:ok, %Credential{}}

      iex> delete_credential(credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_credential(%Credential{} = credential) do
    Repo.delete(credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credential changes.

  ## Examples

      iex> change_credential(credential)
      %Ecto.Changeset{source: %Credential{}}

  """
  def change_credential(%Credential{} = credential) do
    Credential.changeset(credential, %{})
  end

  alias OmegaBravera.Accounts.Setting

  @doc """
  Returns the list of settings.

  ## Examples

      iex> list_settings()
      [%Setting{}, ...]

  """
  def list_settings do
    Repo.all(Setting)
  end

  @doc """
  Gets a single setting.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!(123)
      %Setting{}

      iex> get_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_setting!(id), do: Repo.get!(Setting, id)

  @doc """
  Creates a setting.

  ## Examples

      iex> create_setting(%{field: value})
      {:ok, %Setting{}}

      iex> create_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_setting(attrs \\ %{}) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting(setting, %{field: new_value})
      {:ok, %Setting{}}

      iex> update_setting(setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Setting.

  ## Examples

      iex> delete_setting(setting)
      {:ok, %Setting{}}

      iex> delete_setting(setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_setting(%Setting{} = setting) do
    Repo.delete(setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{source: %Setting{}}

  """
  def change_setting(%Setting{} = setting) do
    Setting.changeset(setting, %{})
  end

  alias OmegaBravera.Accounts.AdminUser

  @doc """
  Returns the list of admin_users.

  ## Examples

      iex> list_admin_users()
      [%AdminUser{}, ...]

  """
  def list_admin_users do
    Repo.all(AdminUser)
  end

  @doc """
  Gets a single admin_user.

  Raises `Ecto.NoResultsError` if the Admin user does not exist.

  ## Examples

      iex> get_admin_user!(123)
      %AdminUser{}

      iex> get_admin_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin_user!(id), do: Repo.get!(AdminUser, id)

  @doc """
  Creates a admin_user.

  ## Examples

      iex> create_admin_user(%{field: value})
      {:ok, %AdminUser{}}

      iex> create_admin_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_admin_user(attrs \\ %{}) do
    %AdminUser{}
    |> AdminUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a admin_user.

  ## Examples

      iex> update_admin_user(admin_user, %{field: new_value})
      {:ok, %AdminUser{}}

      iex> update_admin_user(admin_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_user(%AdminUser{} = admin_user, attrs) do
    admin_user
    |> AdminUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a AdminUser.

  ## Examples

      iex> delete_admin_user(admin_user)
      {:ok, %AdminUser{}}

      iex> delete_admin_user(admin_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_admin_user(%AdminUser{} = admin_user) do
    Repo.delete(admin_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin_user changes.

  ## Examples

      iex> change_admin_user(admin_user)
      %Ecto.Changeset{source: %AdminUser{}}

  """
  def change_admin_user(%AdminUser{} = admin_user) do
    AdminUser.changeset(admin_user, %{})
  end

  def create_or_update_donor_opt_in_mailing_list(donor, ngo, attrs) do
    attrs =
      attrs
      |> Map.put_new("donor_id", donor.id)
      |> Map.put_new("ngo_id", ngo.id)

    case Repo.get_by(Accounts.DonorOptInMailingList, donor_id: donor.id, ngo_id: ngo.id) do
      nil ->
        case create_donor_opt_in_mailing_list(attrs) do
          {:error, reason} -> {:error, reason}
          updated -> updated
        end

      donor_opt_in_mailing_list ->
        case update_donor_opt_in_mailing_list(donor_opt_in_mailing_list, attrs) do
          {:error, reason} -> {:error, reason}
          inserted -> inserted
        end
    end
  end

  def create_donor_opt_in_mailing_list(attrs) do
    %Accounts.DonorOptInMailingList{}
    |> Accounts.DonorOptInMailingList.changeset(attrs)
    |> Repo.insert()
  end

  def update_donor_opt_in_mailing_list(donor_opt_in_mailing_list, attrs) do
    donor_opt_in_mailing_list
    |> Accounts.DonorOptInMailingList.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a user in an :ok tuple if user is found by email and correct password.
  Otherwise an error tuple is returned.
  """
  def authenticate_admin_user_by_email_and_pass(email, given_pass) do
    email = String.downcase(email)

    user =
      from(u in AdminUser, where: fragment("lower(?) = ?", u.email, ^email))
      |> Repo.one()

    cond do
      user && Comeonin.Bcrypt.checkpw(given_pass, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        Comeonin.Bcrypt.dummy_checkpw()
        {:error, :not_found}
    end
  end

  def get_opt_in_ngo_mailing_list(id) do
    from(
      donor_opt_in in Accounts.DonorOptInMailingList,
      where: donor_opt_in.ngo_id == ^id and donor_opt_in.opt_in == true,
      join: donor in assoc(donor_opt_in, :donor),
      join: ngo in assoc(donor_opt_in, :ngo),
      select: [
        donor.firstname,
        donor.lastname,
        donor.email,
        ngo.name,
        fragment("TO_CHAR(? :: DATE, 'dd-mm-yyyy mm-hh')", donor_opt_in.updated_at)
      ]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of donors.

  ## Examples

      iex> list_donors()
      [%Donor{}, ...]

  """
  def list_donors do
    Repo.all(Donor)
  end

  @doc """
  Gets a single donor.

  Raises `Ecto.NoResultsError` if the Donor does not exist.

  ## Examples

      iex> get_donor!(123)
      %Donor{}

      iex> get_donor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_donor!(id), do: Repo.get!(Donor, id)

  @doc """
  Creates a donor.

  ## Examples

      iex> create_donor(%{field: value})
      {:ok, %Donor{}}

      iex> create_donor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_donor(attrs \\ %{}) do
    %Donor{}
    |> Donor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a donor.

  ## Examples

      iex> update_donor(donor, %{field: new_value})
      {:ok, %Donor{}}

      iex> update_donor(donor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_donor(%Donor{} = donor, attrs) do
    donor
    |> Donor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Donor.

  ## Examples

      iex> delete_donor(donor)
      {:ok, %Donor{}}

      iex> delete_donor(donor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_donor(%Donor{} = donor) do
    Repo.delete(donor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking donor changes.

  ## Examples

      iex> change_donor(donor)
      %Ecto.Changeset{source: %Donor{}}

  """
  def change_donor(%Donor{} = donor) do
    Donor.changeset(donor, %{})
  end

  def create_partner_user(attrs \\ %{}) do
    %PartnerUser{}
    |> PartnerUser.changeset(attrs)
    |> Repo.insert()
  end

  def create_partner_user_and_organization(attrs) do
    result =
      %OrganizationMember{organization: nil, partner_user: nil}
      |> OrganizationMember.register_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, %{partner_user: partner_user}} ->
        Notifier.partner_user_signup_email(partner_user)

      _ ->
        :ok
    end

    result
  end

  def update_partner_user(partner_user, attrs) do
    partner_user
    |> PartnerUser.update_changeset(attrs)
    |> Repo.update()
  end

  def update_partner_user_password(partner_user, attrs) do
    partner_user
    |> PartnerUser.password_update_changeset(attrs)
    |> Repo.update()
  end

  def delete_partner_user(partner_user), do: Repo.delete(partner_user)

  def get_partner_user!(id), do: Repo.get!(PartnerUser, id)

  def partner_user_auth(username, password) do
    with {:ok, partner_user} <- get_partner_user_by_email_or_username(username),
         do: verify_partner_user_password(password, partner_user)
  end

  @doc """
  Sets up a changeset for use in forms.
  """
  def change_partner_user(partner_user, attrs \\ %{}),
    do: PartnerUser.changeset(partner_user, attrs)

  @doc """
  Gets a partner user by their email address.
  """
  @spec get_partner_user_by_email_or_username(String.t()) ::
          {:ok, PartnerUser.t()} | {:error, :user_does_not_exist}
  def get_partner_user_by_email_or_username(email_or_username) do
    user =
      from(p in PartnerUser,
        where: p.email == ^email_or_username or p.username == ^email_or_username,
        limit: 1
      )
      |> Repo.one()

    case user do
      nil ->
        {:error, :user_does_not_exist}

      partner_user ->
        {:ok, partner_user}
    end
  end

  @doc """
  Resets a users password and send the email to them.
  """
  @spec reset_partner_user_password(PartnerUser.t()) :: PartnerUser.t()
  def reset_partner_user_password(partner_user) do
    {:ok, partner_user} =
      partner_user
      |> PartnerUser.reset_password_changeset(%{
        reset_token: Tools.random_string(),
        reset_token_created: DateTime.utc_now()
      })
      |> Repo.update()

    :ok = Notifier.send_password_reset_email(partner_user)
    partner_user
  end

  def get_partner_user_by_reset_password_token(token) do
    partner_user =
      from(u in PartnerUser, where: u.reset_token == ^token)
      |> Repo.one()

    case partner_user do
      nil ->
        {:error, :user_not_found}

      partner_user ->
        if Tools.expired?(partner_user.reset_token_created) do
          {:error, :token_expired}
        else
          {:ok, partner_user}
        end
    end
  end

  @doc """
  Allows a user to set their password if they have a token and not expired.
  """
  def set_partner_user_password(token, params) do
    with {:ok, partner_user} <- get_partner_user_by_reset_password_token(token),
         {:ok, partner_user} <- update_partner_user_password(partner_user, params) do
      partner_user
      |> PartnerUser.reset_password_changeset(%{
        reset_token: nil,
        reset_token_created: nil
      })
      |> Repo.update()
    else
      error -> error
    end
  end

  defp verify_partner_user_password(password, partner_user) do
    if checkpw(password, partner_user.password_hash) do
      {:ok, partner_user}
    else
      {:error, :invalid_password}
    end
  end

  def get_partner_user_by_email_activation_token(email_activation_token) do
    case Repo.get_by(PartnerUser, email_activation_token: email_activation_token) do
      nil ->
        {:error, :no_such_user}

      partner_user ->
        {:ok, partner_user}
    end
  end

  @doc """
  Markes a partner user as their email verified.
  """
  @spec verify_partner_user_email(PartnerUser.t()) :: {:ok, PartnerUser.t()}
  def verify_partner_user_email(%PartnerUser{} = partner_user),
    do: update_partner_user(partner_user, %{email_verified: true})

  @doc """
  Returns the list of organization.

  ## Examples

      iex> list_organization()
      [%Organization{}, ...]

  """
  def list_organization do
    Repo.all(Organization)
  end

  def list_organization_options() do
    from(o in Organization, select: {o.name, o.id})
    |> Repo.all()
  end

  def list_organization_with_member_count_query() do
    from(o in Organization,
      left_join: om in OrganizationMember,
      on: o.id == om.organization_id,
      windows: [organization_id: [partition_by: o.id]],
      distinct: true,
      select: %{o | member_count: coalesce(over(count(om.id), :organization_id), 0)}
    )
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Creates a organization.

  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization.

  ## Examples

      iex> update_organization(organization, %{field: new_value})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

      iex> delete_organization(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  @doc """
  Returns the list of organization_members.

  ## Examples

      iex> list_organization_members()
      [%OrganizationMember{}, ...]

  """
  def list_organization_members do
    Repo.all(OrganizationMember)
  end

  def list_organization_members_with_preloads_query(preloads \\ []) do
    from(o in OrganizationMember,
      preload: ^preloads
    )
  end

  def list_organization_members_by_partner_user(partner_user_id) do
    from(o in OrganizationMember,
      where: o.partner_user_id == ^partner_user_id,
      select: o.organization_id
    )
    |> Repo.all()
  end

  @doc """
  Gets a single organization_member.

  Raises `Ecto.NoResultsError` if the Organization member does not exist.

  ## Examples

      iex> get_organization_member!(123)
      %OrganizationMember{}

      iex> get_organization_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization_member!(id) do
    from(o in OrganizationMember, where: o.id == ^id, preload: [:partner_user])
    |> Repo.one!()
  end

  @doc """
  Creates a organization_member.

  ## Examples

      iex> create_organization_member(%{field: value})
      {:ok, %OrganizationMember{}}

      iex> create_organization_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization_member(attrs \\ %{}) do
    %OrganizationMember{}
    |> OrganizationMember.changeset(attrs)
    |> Repo.insert()
  end

  def create_organization_partner_user(attrs \\ %{}) do
    %OrganizationMember{}
    |> OrganizationMember.admin_create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization_member.

  ## Examples

      iex> update_organization_member(organization_member, %{field: new_value})
      {:ok, %OrganizationMember{}}

      iex> update_organization_member(organization_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization_member(%OrganizationMember{} = organization_member, attrs) do
    organization_member
    |> OrganizationMember.changeset(attrs)
    |> Repo.update()
  end

  def update_organization_partner_user(%OrganizationMember{} = organization_member, attrs) do
    organization_member
    |> OrganizationMember.admin_create_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization_member.

  ## Examples

      iex> delete_organization_member(organization_member)
      {:ok, %OrganizationMember{}}

      iex> delete_organization_member(organization_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization_member(%OrganizationMember{} = organization_member) do
    Repo.delete(organization_member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization_member changes.

  ## Examples

      iex> change_organization_member(organization_member)
      %Ecto.Changeset{data: %OrganizationMember{}}

  """
  def change_organization_member(%OrganizationMember{} = organization_member, attrs \\ %{}) do
    OrganizationMember.changeset(organization_member, attrs)
  end

  def get_partner_user_email_by_group(group_id) do
    from(pu in PartnerUser,
      left_join: om in OrganizationMember,
      on: pu.id == om.partner_user_id,
      left_join: p in OmegaBravera.Groups.Partner,
      on: om.organization_id == p.organization_id,
      where: p.id == ^group_id,
      order_by: [asc: pu.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def get_partner_user_email_by_offer(offer_id) do
    from(pu in PartnerUser,
      left_join: om in OrganizationMember,
      on: pu.id == om.partner_user_id,
      left_join: o in OmegaBravera.Offers.Offer,
      on: om.organization_id == o.organization_id,
      where: o.id == ^offer_id,
      order_by: [asc: pu.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  list new members joined yesterday
  """
  @spec list_orgs_with_new_members :: [Organization.t()]
  def list_orgs_with_new_members do
    from(org in Organization,
      left_join: group in assoc(org, :groups),
      left_join: member in assoc(group, :members),
      where: fragment("? BETWEEN now() - interval '1 days' AND now()", member.inserted_at),
      group_by: [org.id],
      preload: [organization_members: [:partner_user]]
    )
    |> Repo.all()
  end

  @doc """
  list new group members of org
  """
  @spec list_new_group_members_of_org(String.t()) :: [Member.t()]
  def list_new_group_members_of_org(org_id) do
    from(user in User,
      left_join: member in assoc(user, :memberships),
      left_join: group in assoc(member, :partner),
      where:
        group.organization_id == ^org_id and
          fragment("? BETWEEN now() - interval '1 days' AND now()", member.inserted_at),
      distinct: true
    )
    |> Repo.all()
  end

  @doc """
  create friend request
  """
  @spec create_friend_request(map()) :: {:ok, Friend.t()} | {:error, %Ecto.Changeset{}}
  def create_friend_request(%{receiver_id: receiver_id, requester_id: requester_id} = attrs) do
    with nil <- find_existing_friend(receiver_id, requester_id) do
      %Friend{}
      |> Friend.request_changeset(attrs)
      |> Repo.insert()
      |> notify_user()
    else
      %Friend{} = friend ->
        {:ok, friend}
    end
  end

  @spec find_existing_friend(integer(), integer()) :: Friend.t() | nil
  def find_existing_friend(receiver_id, requester_id) do
    from(f in Friend,
      where:
        (f.receiver_id == ^receiver_id and f.requester_id == ^requester_id) or
          (f.receiver_id == ^requester_id and f.requester_id == ^receiver_id)
    )
    |> Repo.one()
  end

  @doc """
  accept friend request
  """
  @spec accept_friend_request(Friend.t()) :: {:ok, Friend.t()} | {:error, %Ecto.Changeset{}}
  def accept_friend_request(%Friend{} = friend) do
    friend
    |> Friend.accept_changeset(%{})
    |> Repo.update()
    |> notify_user()
  end

  @spec notify_user(tuple()) :: tuple()
  defp notify_user({:ok, %Friend{} = friend} = tuple) do
    OmegaBravera.Notifications.Jobs.NotifyNewFriend.new(friend)
    |> Oban.insert()

    tuple
  end

  defp notify_user(tuple), do: tuple

  @doc """
  reject friend request
  """
  @spec reject_friend_request(Friend.t()) :: {:ok, Friend.t()} | {:error, %Ecto.Changeset{}}
  def reject_friend_request(%Friend{} = friend), do: Repo.delete(friend)

  @doc """
  mute or unmute receiver's notification
  """
  def mute_receiver_notification(friend, attrs \\ %{}) do
    friend
    |> Friend.mute_receiver_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  mute or unmute requester's notification
  """
  def mute_requester_notification(friend, attrs \\ %{}) do
    friend
    |> Friend.mute_requester_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  get friend by receiver_id and requester_id
  """
  @spec get_friend_by_receiver_id_requester_id(integer(), integer()) :: Friend.t() | nil
  def get_friend_by_receiver_id_requester_id(receiver_id, requester_id) do
    from(f in Friend, where: f.receiver_id == ^receiver_id and f.requester_id == ^requester_id)
    |> Repo.one()
  end

  @doc """
  list and search accepted friends
  """
  @spec list_accepted_friends(integer(), String.t(), map()) :: [User.t()]
  def list_accepted_friends(user_id, keyword, pagination_args) do
    search = "%#{keyword}%"

    from(u in User,
      left_join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      where:
        f.status == :accepted and (f.receiver_id == ^user_id or f.requester_id == ^user_id) and
          u.id != ^user_id and ilike(u.username, ^search),
      order_by: [u.username]
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  list friend requests
  """
  @spec list_friend_requests(integer()) :: [Friend.t()]
  def list_friend_requests(user_id) do
    from(f in Friend, where: f.status == :pending and f.receiver_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  search and list users that can send friend request to
  """
  @spec list_possible_friends(integer(), String.t(), map()) :: [User.t()]
  def list_possible_friends(user_id, keyword, pagination_args) do
    search = "%#{keyword}%"

    from(u in User,
      left_join: f in Friend,
      on:
        (f.receiver_id == u.id and f.requester_id == ^user_id) or
          (f.requester_id == u.id and f.receiver_id == ^user_id),
      where:
        u.id != ^user_id and ilike(u.username, ^search) and
          (is_nil(f.id) or f.status != :accepted),
      order_by: u.username,
      select: %{u | friend_status: fragment("CASE WHEN ? THEN 'stranger' ELSE 'pending' END", is_nil(f.id))}
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  get information of the given user for comparison
  """
  @spec get_user_for_comparison(integer()) :: User.t()
  def get_user_for_comparison(user_id) do
    now = Timex.now()
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)
    beginning_of_week = Timex.beginning_of_week(now)
    end_of_week = Timex.end_of_week(now)
    beginning_of_month = Timex.beginning_of_month(now)
    end_of_month = Timex.end_of_month(now)

    from(u in User,
      left_join: ttd in subquery(activity_query(beginning_of_day, end_of_day)),
      on: ttd.user_id == u.id,
      left_join: wtd in subquery(activity_query(beginning_of_week, end_of_week)),
      on: wtd.user_id == u.id,
      left_join: mtd in subquery(activity_query(beginning_of_month, end_of_month)),
      on: mtd.user_id == u.id,
      where: u.id == ^user_id,
      group_by: [u.id, ttd.distance, wtd.distance, mtd.distance],
      select: %{
        u
        | total_kilometers_today: coalesce(ttd.distance, 0),
          total_kilometers_this_week: coalesce(wtd.distance, 0),
          total_kilometers_this_month: coalesce(mtd.distance, 0)
      }
    )
    |> Repo.one()
  end

  @doc """
  list all friends with chat messages
  """
  @spec list_accepted_friends_with_chat_messages(integer(), integer()) :: [User.t()]
  def list_accepted_friends_with_chat_messages(user_id, limit \\ 10) do
    from(u in User,
      as: :user,
      left_join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      left_join: message in PrivateChatMessage,
      on: message.from_user_id == u.id or message.to_user_id == u.id,
      left_lateral_join:
        pm in subquery(
          from(private_chat in PrivateChatMessage,
            where:
              private_chat.from_user_id == parent_as(:user).id or
                private_chat.to_user_id == parent_as(:user).id,
            order_by: [desc: :inserted_at],
            limit: ^limit
          )
        ),
      on: pm.from_user_id == ^user_id or pm.to_user_id == ^user_id,
      where:
        f.status == :accepted and (f.receiver_id == ^user_id or f.requester_id == ^user_id) and
          u.id != ^user_id,
      preload: [
        private_chat_messages:
          {message, [:from_user, :to_user, reply_to_message: [:from_user, :to_user]]}
      ],
      select: %{
        u
        | chat_muted:
            fragment(
              "CASE WHEN ? THEN ? ElSE ? END",
              f.requester_id == u.id,
              not is_nil(f.requester_muted),
              not is_nil(f.receiver_muted)
            )
      }
    )
    |> Repo.all()
  end

  @doc """
  create new private_chat_message
  """
  @spec create_private_chat_message(map()) ::
          {:ok, PrivateChatMessage.t()} | {:error, Ecto.Changeset.t()}
  def create_private_chat_message(attrs \\ %{}) do
    %PrivateChatMessage{}
    |> PrivateChatMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  update private message
  """
  @spec update_private_message(PrivateChatMessage.t(), map()) ::
          {:ok, PrivateChatMessage.t()} | {:error, Ecto.Changeset.t()}
  def update_private_message(message, attrs \\ %{}) do
    message
    |> PrivateChatMessage.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  delete private message
  """
  @spec delete_private_message(PrivateChatMessage.t()) ::
          {:ok, PrivateChatMessage.t()} | {:error, Ecto.Changeset.t()}
  def delete_private_message(%PrivateChatMessage{} = message), do: Repo.delete(message)

  def get_private_message_query(message_id) do
    from(pm in PrivateChatMessage,
      where: pm.id == ^message_id,
      preload: [:from_user, :to_user, reply_to_message: [:from_user, :to_user]]
    )
  end

  @doc """
  Get private message with preload
  """
  @spec get_private_message!(String.t()) :: PrivateChatMessage.t()
  def get_private_message!(message_id) do
    get_private_message_query(message_id)
    |> Repo.one!()
  end

  def get_private_message(message_id) do
    get_private_message_query(message_id)
    |> Repo.one()
  end

  @doc """
  Get previous private messages
  """
  @spec get_previous_private_messages(String.t(), integer()) :: [PrivateChatMessage.t()]
  def get_previous_private_messages(message_id, limit) do
    message = get_private_message!(message_id)

    from(pm in PrivateChatMessage,
      where:
        pm.inserted_at <= ^message.inserted_at and pm.id != ^message.id and
          ((pm.from_user_id == ^message.from_user_id and pm.to_user_id == ^message.to_user_id) or
             (pm.from_user_id == ^message.to_user_id and pm.to_user_id == ^message.from_user_id)),
      limit: ^limit,
      preload: [:from_user, :to_user, reply_to_message: [:from_user, :to_user]]
    )
    |> Repo.all()
  end

  @doc """
  Get unread count from message_id
  """
  @spec get_unread_private_message_count(String.t()) :: integer()
  def get_unread_private_message_count(message_id) do
    case get_private_message(message_id) do
      nil ->
        0

      message ->
        from(pm in PrivateChatMessage,
          select: count(),
          where:
            pm.inserted_at >= ^message.inserted_at and pm.id != ^message.id and
              ((pm.from_user_id == ^message.from_user_id and pm.to_user_id == ^message.to_user_id) or
                 (pm.from_user_id == ^message.to_user_id and
                    pm.to_user_id == ^message.from_user_id))
        )
        |> Repo.one()
    end
  end

  def datasource, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(queryable, _), do: queryable
end
