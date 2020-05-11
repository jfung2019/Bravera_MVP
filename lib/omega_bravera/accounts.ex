defmodule OmegaBravera.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Ecto.Multi
  alias OmegaBravera.Accounts.Jobs

  alias OmegaBravera.{
    Repo,
    Accounts,
    Accounts.User,
    Accounts.Credential,
    Accounts.Donor,
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
    Activity.ActivityAccumulator
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

  def api_get_leaderboard_this_week() do
    now = Timex.now()
    beginning = Timex.beginning_of_week(now)
    end_of_week = Timex.end_of_week(now)

    point_query =
      from(p in Point, select: %{value: sum(p.value), user_id: p.user_id}, group_by: p.user_id)

    activity_query =
      from(a in ActivityAccumulator,
        select: %{distance: sum(a.distance), user_id: a.user_id},
        group_by: a.user_id,
        where:
          a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
            not is_nil(a.device_id) and is_nil(a.strava_id) and a.start_date >= ^beginning and
            a.start_date <= ^end_of_week
      )

    from(
      u in User,
      left_join: a in subquery(activity_query),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query),
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

  def api_get_leaderboard_all_time() do
    point_query =
      from(p in Point, select: %{value: sum(p.value), user_id: p.user_id}, group_by: p.user_id)

    activity_query =
      from(a in ActivityAccumulator,
        select: %{distance: sum(a.distance), user_id: a.user_id},
        group_by: a.user_id,
        where:
          a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
            not is_nil(a.device_id) and is_nil(a.strava_id)
      )

    from(
      u in User,
      left_join: a in subquery(activity_query),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query),
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

  def user_live_challenges(user_id) do
    from(oc in OfferChallenge,
      where: oc.status == "active" and oc.user_id == ^user_id,
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
  Prepares a list of current users with settings and extra fields ready in admin panel.
  """
  def list_users_for_admin do
    today = Timex.today()
    before = today |> Timex.shift(days: -30)

    rewards_query =
      from(r in OmegaBravera.Offers.OfferRedeem,
        group_by: r.user_id,
        left_join: oc in assoc(r, :offer_challenge),
        on: oc.status == ^"complete",
        select: %{user_id: r.user_id, count: count(r.id)}
      )

    rewards_redeemed_query =
      from(r in OmegaBravera.Offers.OfferRedeem,
        group_by: r.user_id,
        where: r.status == "redeemed",
        select: %{user_id: r.user_id, count: count(r.id)}
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
      select: %{
        u
        | active: fragment("? > 0", count(a.id)),
          device_type:
            fragment(
              "CASE WHEN ? ILIKE '%-%' THEN 'iOS' WHEN ? IS NOT NULL THEN 'Android' ELSE '' END",
              d.uuid,
              d.uuid
            ),
          number_of_claimed_rewards: coalesce(cr.count, 0),
          number_of_rewards: coalesce(r.count, 0)
      },
      group_by: [u.id, d.uuid, r.count, cr.count]
    )
    |> Repo.all()
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
end
