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
  @endpoint OmegaBraveraWeb.Endpoint
  @user_channel OmegaBraveraWeb.UserChannel
  require Logger

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
    Groups.ChatMessage,
    Accounts.Organization,
    Accounts.OrganizationMember,
    Accounts.Friend,
    Accounts.PrivateChatMessage
  }

  def get_all_athlete_ids() do
    query = from(s in Trackers.Strava, select: s.athlete_id)
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
      join: s in Trackers.Strava,
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
    from(s in Trackers.Strava, where: s.athlete_id == ^athlete_id) |> Repo.one()
  end

  def get_strava_challengers(athlete_id) do
    team_challengers =
      from(s in Trackers.Strava,
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
      from(s in Trackers.Strava,
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
      from(s in Trackers.Strava,
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
      from(s in Trackers.Strava,
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
    from(s in Trackers.Strava, where: s.user_id == ^user_id)
    |> Repo.one()
  end

  def remove_all_stravas do
    Trackers.list_stravas()
    |> Enum.map(fn %{refresh_token: refresh_token} = strava ->
      try do
        client = Strava.Auth.get_token!(grant_type: "refresh_token", refresh_token: refresh_token)

        Trackers.update_strava(strava, %{
          token: client.token.access_token,
          refresh_token: client.token.refresh_token,
          token_expires_at: Timex.from_unix(client.token.expires_at)
        })

        HTTPoison.post("https://www.strava.com/oauth/deauthorize", %{
          access_token: client.token.access_token
        })
      rescue
        error -> Logger.warn("Problem: #{inspect(error)}")
      after
        Trackers.delete_strava(strava)
      end
    end)
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

  @doc """
  Set user as deleted
  remove first_name, last_name, dob, location, email, profile_picture
  """
  def gdpr_delete_user(user_id) do
    Multi.new()
    |> Multi.update(:delete_user, User.gdpr_delete_changeset(get_user!(user_id)))
    |> Multi.delete_all(:delete_user_setting, fn _result ->
      from(s in Accounts.Setting, where: s.user_id == ^user_id)
    end)
    |> Repo.transaction()
  end

  def point_query do
    from(ua in "user_agg",
      as: :user_agg,
      left_lateral_join:
        p in subquery(
          from(p in Point,
            select: %{value: sum(p.value), user_id: p.user_id},
            where:
              p.user_id == parent_as(:user_agg).user_id and
                p.inserted_at > parent_as(:user_agg).points_date,
            group_by: p.user_id
          )
        ),
      on: p.user_id == ua.user_id,
      select: %{value: coalesce(ua.points_value, 0) + coalesce(p.value, 0), user_id: ua.user_id}
    )
  end

  defp activity_query(start_date, end_date) do
    from(a in ActivityAccumulator,
      select: %{distance: coalesce(sum(a.distance), 0), user_id: a.user_id},
      group_by: a.user_id,
      where: fragment("? BETWEEN ? AND ?", a.start_date, ^start_date, ^end_date)
    )
  end

  defp activity_query do
    from(a in "user_agg", select: %{distance: coalesce(a.distance, 0), user_id: a.user_id})
  end

  defp last_activity_query(start_date, end_date) do
    from(a in ActivityAccumulator,
      select: %{
        distance: coalesce(sum(a.distance), 0),
        user_id: a.user_id,
        end_date: max(a.end_date)
      },
      group_by: a.user_id,
      where:
        a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
          not is_nil(a.device_id) and is_nil(a.strava_id) and a.start_date >= ^start_date and
          a.start_date <= ^end_date
    )
  end

  defp last_activity_query do
    from(a in ActivityAccumulator,
      select: %{distance: sum(a.distance), user_id: a.user_id, end_date: max(a.end_date)},
      group_by: a.user_id,
      where:
        a.type in ^OmegaBravera.Activity.ActivityOptions.points_allowed_activities() and
          not is_nil(a.device_id) and is_nil(a.strava_id)
    )
  end

  defp api_get_leaderboard_this_week_query(user_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_join: f in subquery(is_friend_query(user_id)),
      on: f.id == u.id,
      left_join: a in subquery(activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email) and not is_nil(u.id),
      select: %{
        u
        | total_points_this_week: coalesce(p.value, 0),
          total_kilometers_this_week: coalesce(a.distance, 0),
          is_friend: coalesce(f.is_friend, false)
      },
      group_by: [u.id, p.value, a.distance, f.is_friend],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  defp api_get_leaderboard_this_month_query(user_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_join: f in subquery(is_friend_query(user_id)),
      on: f.id == u.id,
      left_join: a in subquery(activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email) and not is_nil(u.id),
      select: %{
        u
        | total_points_this_month: coalesce(p.value, 0),
          total_kilometers_this_month: coalesce(a.distance, 0),
          is_friend: coalesce(f.is_friend, false)
      },
      group_by: [u.id, p.value, a.distance, f.is_friend],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  defp api_get_leaderboard_all_time_query(user_id) do
    from(
      u in User,
      left_join: f in subquery(is_friend_query(user_id)),
      on: f.id == u.id,
      left_join: a in subquery(activity_query()),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email) and not is_nil(u.id),
      select: %{
        u
        | total_points: coalesce(p.value, 0),
          total_kilometers: coalesce(a.distance, 0),
          is_friend: coalesce(f.is_friend, false)
      },
      group_by: [u.id, p.value, a.distance, f.is_friend],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  defp api_get_leaderboard_this_week_query do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_join: a in subquery(activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email),
      select: %{
        u
        | total_points_this_week: fragment("ROUND(?, 2)", coalesce(p.value, 0)),
          total_kilometers_this_week: fragment("ROUND(?, 2)", coalesce(a.distance, 0))
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  defp api_get_leaderboard_this_month_query do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_join: a in subquery(activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email),
      select: %{
        u
        | total_points_this_month: fragment("ROUND(?, 2)", coalesce(p.value, 0)),
          total_kilometers_this_month: fragment("ROUND(?, 2)", coalesce(a.distance, 0))
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  defp api_get_leaderboard_all_time_query do
    from(
      u in User,
      left_join: a in subquery(activity_query()),
      on: a.user_id == u.id,
      left_join: p in subquery(point_query()),
      on: p.user_id == u.id,
      where: not is_nil(u.email),
      select: %{
        u
        | total_points: fragment("ROUND(?, 2)", coalesce(p.value, 0)),
          total_kilometers: fragment("ROUND(?, 2)", coalesce(a.distance, 0))
      },
      group_by: [u.id, p.value, a.distance],
      order_by: [desc_nulls_last: a.distance]
    )
  end

  @doc """
  Get user details of the week for the group longest (week, longest: 50+km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_week_longest(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_week_longest(organization_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance > 50,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the week for the group long (week, long: 36 to 50km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_week_long(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_week_long(organization_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 36 and a.distance < 50,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the week for the group moderate (week, moderate: 21 to 35km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_week_moderate(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_week_moderate(organization_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 21 and a.distance < 35,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the week for the group low (week, low: 0 to 20km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_week_low(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_week_low(organization_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(seven_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email) and
          (not is_nil(a.distance) and a.distance >= 0 and a.distance < 20),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the month for the group longest (month, longest: 200+km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_month_longest(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_month_longest(organization_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance > 200,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the month for the group long (month, long: 141 to 200km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_month_long(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_month_long(organization_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 141 and a.distance < 200,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the month for the group moderate (month, moderate: 61 to 140km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_month_moderate(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_month_moderate(organization_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 61 and a.distance < 140,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of the month for the group low (month, low: 0 to 80km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_month_low(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_month_low(organization_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query(thirty_days_ago, now)),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email) and
          (not is_nil(a.distance) and a.distance >= 0 and a.distance < 80),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of all time for the group longest (all time, longest: 8000+ km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_all_time_longest(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_all_time_longest(organization_id) do
    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query()),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 8000,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of all time for the group long (all time, long: 5000+ km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_dashboard_org_all_time_long(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_dashboard_org_all_time_long(organization_id) do
    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query()),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 5000 and a.distance < 8000,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of all time for the group moderate (all time, moderate: 3000+ km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_all_time_moderate(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_all_time_moderate(organization_id) do
    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query()),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      where: a.distance >= 3000 and a.distance < 5000,
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Get user details of all time for the group low (all time, low: 1000+ km) within the joined organization for the doughnut chart in dashboard.
  """
  @spec get_user_details_dashboard_org_all_time_low(String.t()) :: %{
          username: String.t(),
          distance: integer(),
          last_activity: String.t()
        }
  def get_user_details_dashboard_org_all_time_low(organization_id) do
    from(
      u in User,
      left_lateral_join: a in subquery(last_activity_query()),
      on: a.user_id == u.id,
      where:
        u.id in subquery(
          from(o in Organization,
            left_join: m in assoc(o, :group_members),
            where: o.id == ^organization_id,
            select: m.user_id
          )
        ) and not is_nil(u.email) and
          (not is_nil(a.distance) and a.distance >= 1000 and a.distance < 3000),
      select: %{
        username: u.username,
        distance: fragment("ROUND(?, 2)", coalesce(a.distance, 0)),
        last_activity: fragment("TO_CHAR(?, 'YYYY-MM-DD HH:MI')", a.end_date)
      },
      group_by: [u.id, a.distance, a.end_date],
      order_by: [desc_nulls_last: a.distance]
    )
    |> Repo.all()
  end

  @doc """
  Count and get the number of users that meets specific amount of distance for all time and
  grouped them accordingly (there are 4 groups in total) for the doughnut chart within the joined organization.
  """
  @spec get_dashboard_org_all_time_group(String.t()) ::
          %{
            total_user_count_group_longest: integer(),
            total_user_count_group_long: integer(),
            total_user_count_group_moderate: integer(),
            total_user_count_group_low: integer()
          }
  def get_dashboard_org_all_time_group(organization_id) do
    from(
      t in subquery(
        from(
          u in User,
          left_lateral_join: a in subquery(activity_query()),
          on: a.user_id == u.id,
          where:
            u.id in subquery(
              from(o in Organization,
                left_join: m in assoc(o, :group_members),
                where: o.id == ^organization_id,
                select: m.user_id
              )
            ) and not is_nil(u.email) and not is_nil(a.distance),
          select: %{
            distance: coalesce(a.distance, 0),
            user_id: u.id
          },
          group_by: [u.id, a.distance],
          order_by: [asc_nulls_last: a.distance]
        )
      ),
      select: %{
        total_user_count_group_longest:
          fragment("SUM(CASE WHEN ? >= 8000 THEN 1 ELSE 0 END)", t.distance),
        total_user_count_group_long:
          fragment(
            "SUM(CASE WHEN ? >= 5000 AND ? <8000 THEN 1 ELSE 0 END)",
            t.distance,
            t.distance
          ),
        total_user_count_group_moderate:
          fragment(
            "SUM(CASE WHEN ? >= 3000 AND ? <5000 THEN 1 ELSE 0 END)",
            t.distance,
            t.distance
          ),
        total_user_count_group_low:
          fragment(
            "SUM(CASE WHEN ? >= 1000 AND ? <3000 THEN 1 ELSE 0 END)",
            t.distance,
            t.distance
          )
      }
    )
    |> Repo.one()
  end

  @doc """
  Count and get the number of users that meets specific amount of distance for 7 days and
  grouped them accordingly (there are 4 groups in total) for the doughnut chart within the joined organization.
  """
  @spec get_dashboard_org_week_group(String.t()) ::
          %{
            total_user_count_group_longest: integer(),
            total_user_count_group_long: integer(),
            total_user_count_group_moderate: integer(),
            total_user_count_group_low: integer()
          }
  def get_dashboard_org_week_group(organization_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      t in subquery(
        from(
          u in User,
          left_lateral_join: a in subquery(activity_query(seven_days_ago, now)),
          on: a.user_id == u.id,
          where:
            u.id in subquery(
              from(o in Organization,
                left_join: m in assoc(o, :group_members),
                where: o.id == ^organization_id,
                select: m.user_id
              )
            ) and not is_nil(u.email) and not is_nil(a.distance),
          select: %{
            distance: coalesce(a.distance, 0),
            user_id: u.id
          },
          group_by: [u.id, a.distance],
          order_by: [asc_nulls_last: a.distance]
        )
      ),
      select: %{
        total_user_count_group_longest:
          fragment("SUM(CASE WHEN ? >= 50 THEN 1 ELSE 0 END)", t.distance),
        total_user_count_group_long:
          fragment("SUM(CASE WHEN ? >= 36 AND ? < 50 THEN 1 ELSE 0 END)", t.distance, t.distance),
        total_user_count_group_moderate:
          fragment("SUM(CASE WHEN ? >= 21 AND ? < 35 THEN 1 ELSE 0 END)", t.distance, t.distance),
        total_user_count_group_low:
          fragment("SUM(CASE WHEN ? >= 0 AND ? < 20 THEN 1 ELSE 0 END)", t.distance, t.distance)
      }
    )
    |> Repo.one()
  end

  @doc """
  Count and get the number of users that meets specific amount of distance for 30 days and
  grouped them accordingly (there are 4 groups in total) for the doughnut chart within the joined organization.
  """
  @spec get_dashboard_org_month_group(String.t()) ::
          %{
            total_user_count_group_longest: integer(),
            total_user_count_group_long: integer(),
            total_user_count_group_moderate: integer(),
            total_user_count_group_low: integer()
          }
  def get_dashboard_org_month_group(organization_id) do
    now = Timex.now()
    thirty_days_ago = Timex.shift(now, days: -30)

    from(
      t in subquery(
        from(
          u in User,
          left_lateral_join: a in subquery(activity_query(thirty_days_ago, now)),
          on: a.user_id == u.id,
          where:
            u.id in subquery(
              from(o in Organization,
                left_join: m in assoc(o, :group_members),
                where: o.id == ^organization_id,
                select: m.user_id
              )
            ) and not is_nil(u.email) and not is_nil(a.distance),
          select: %{
            distance: coalesce(a.distance, 0),
            user_id: u.id
          },
          group_by: [u.id, a.distance],
          order_by: [asc_nulls_last: a.distance]
        )
      ),
      select: %{
        total_user_count_group_longest:
          fragment("SUM(CASE WHEN ? >= 200 THEN 1 ELSE 0 END)", t.distance),
        total_user_count_group_long:
          fragment("SUM(CASE WHEN ? >= 141 AND ? <200 THEN 1 ELSE 0 END)", t.distance, t.distance),
        total_user_count_group_moderate:
          fragment("SUM(CASE WHEN ? >= 61 AND ? <140 THEN 1 ELSE 0 END)", t.distance, t.distance),
        total_user_count_group_low:
          fragment("SUM(CASE WHEN ? >= 0 AND ? <80 THEN 1 ELSE 0 END)", t.distance, t.distance)
      }
    )
    |> Repo.one()
  end

  @doc """
  Get Bravera leaderboard of this week.
  """
  @spec api_get_leaderboard_this_week() :: [User.t()]
  def api_get_leaderboard_this_week() do
    api_get_leaderboard_this_week_query()
    |> Repo.all()
  end

  @doc """
  Get Bravera leaderboard of this month.
  """
  @spec api_get_leaderboard_this_month() :: [User.t()]
  def api_get_leaderboard_this_month() do
    api_get_leaderboard_this_month_query()
    |> Repo.all()
  end

  @doc """
  Get overall Bravera leaderboard.
  """
  @spec api_get_leaderboard_all_time() :: [User.t()]
  def api_get_leaderboard_all_time() do
    api_get_leaderboard_all_time_query()
    |> Repo.all()
  end

  @doc """
  Get Bravera leaderboard of this week annotated with is_friend.
  """
  @spec api_get_leaderboard_this_week(UUID.t()) :: [User.t()]
  def api_get_leaderboard_this_week(authenticated_user_id) do
    api_get_leaderboard_this_week_query(authenticated_user_id)
    |> Repo.all()
  end

  @doc """
  Get Bravera leaderboard of this month annotated with is_friend.
  """
  @spec api_get_leaderboard_this_month(UUID.t()) :: [User.t()]
  def api_get_leaderboard_this_month(authenticated_user_id) do
    api_get_leaderboard_this_month_query(authenticated_user_id)
    |> Repo.all()
  end

  @doc """
  Get overall Bravera leaderboard annotated with is_friend.
  """
  @spec api_get_leaderboard_all_time(UUID.t()) :: [User.t()]
  def api_get_leaderboard_all_time(authenticated_user_id) do
    api_get_leaderboard_all_time_query(authenticated_user_id)
    |> Repo.all()
  end

  defp filter_query_with_user_friend(query, user_id) do
    from(q in query,
      left_join: f in Friend,
      on: f.receiver_id == q.id or f.requester_id == q.id,
      where: f.status == :accepted and (f.receiver_id == ^user_id or f.requester_id == ^user_id)
    )
  end

  defp is_friend_query(user_id) do
    from(
      u in User,
      join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      where:
        not is_nil(u.id) and
          f.status == :accepted and
          (f.receiver_id == ^user_id or f.requester_id == ^user_id) and
          u.id != ^user_id,
      select: %{
        id: fragment("distinct on (?) ?", u.id, u.id),
        is_friend: true
      }
    )
  end

  @doc """
  Get user's friends leaderboard of this month
  """
  @spec api_get_friend_leaderboard_this_week(String.t()) :: [User.t()]
  def api_get_friend_leaderboard_this_week(user_id) do
    api_get_leaderboard_this_week_query(user_id)
    |> filter_query_with_user_friend(user_id)
    |> Repo.all()
  end

  @doc """
  Get user's friends leaderboard of this month
  """
  @spec api_get_friend_leaderboard_this_month(String.t()) :: [User.t()]
  def api_get_friend_leaderboard_this_month(user_id) do
    api_get_leaderboard_this_month_query(user_id)
    |> filter_query_with_user_friend(user_id)
    |> Repo.all()
  end

  @doc """
  Get overall user's friends leaderboard
  """
  @spec api_get_friend_leaderboard_all_time(String.t()) :: [User.t()]
  def api_get_friend_leaderboard_all_time(user_id) do
    api_get_leaderboard_all_time_query(user_id)
    |> filter_query_with_user_friend(user_id)
    |> Repo.all()
  end

  defp members(partner_id),
    do: from(m in Member, where: m.partner_id == ^partner_id, select: m.user_id)

  @spec get_leaderboad_partner_messages_this_week(integer()) :: any
  def get_leaderboad_partner_messages_this_week(partner_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -7)

    from(
      u in User,
      left_join: cm in ChatMessage,
      on: u.id == cm.user_id,
      where: cm.group_id == ^partner_id and cm.inserted_at >= ^seven_days_ago,
      group_by: u.id,
      order_by: [desc_nulls_last: count(cm.id)],
      select: %{user: u, message_count: count(cm.id)}
    )
    |> Repo.all()
  end

  @spec get_leaderboad_partner_messages_this_month(integer()) :: any
  def get_leaderboad_partner_messages_this_month(partner_id) do
    now = Timex.now()
    seven_days_ago = Timex.shift(now, days: -31)

    from(
      u in User,
      left_join: cm in ChatMessage,
      on: u.id == cm.user_id,
      where: cm.group_id == ^partner_id and cm.inserted_at >= ^seven_days_ago,
      group_by: u.id,
      order_by: [desc_nulls_last: count(cm.id)],
      select: %{user: u, message_count: count(cm.id)}
    )
    |> Repo.all()
  end

  @spec get_leaderboad_partner_messages_all_time(integer()) :: any()
  def get_leaderboad_partner_messages_all_time(partner_id) do
    from(
      u in User,
      left_join: cm in ChatMessage,
      on: u.id == cm.user_id,
      where: cm.group_id == ^partner_id,
      group_by: u.id,
      order_by: [desc_nulls_last: count(cm.id)],
      select: %{user: u, message_count: count(cm.id)}
    )
    |> Repo.all()
  end

  @doc """
  Get user's joined group leaderboard of this week
  """
  @spec api_get_leaderboard_of_partner_this_week(String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_this_week(partner_id) do
    api_get_leaderboard_this_week_query()
    |> where([u], u.id in subquery(members(partner_id)))
    |> Repo.all()
  end

  @doc """
  Get user's joined group leaderboard of this month
  """
  @spec api_get_leaderboard_of_partner_this_month(String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_this_month(partner_id) do
    api_get_leaderboard_this_month_query()
    |> where([u], u.id in subquery(members(partner_id)))
    |> Repo.all()
  end

  @doc """
  Get overall user's joined group leaderboard
  """
  @spec api_get_leaderboard_of_partner_all_time(String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_all_time(partner_id) do
    api_get_leaderboard_all_time_query()
    |> where([u], u.id in subquery(members(partner_id)))
    |> Repo.all()
  end

  @doc """
  Get user's joined group leaderboard of this week
  """
  @spec api_get_leaderboard_of_partner_this_week(String.t(), String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_this_week(authenticated_user_id, partner_id) do
    api_get_leaderboard_this_week_query(authenticated_user_id)
    |> where([u], u.id in ^members(partner_id))
    |> Repo.all()
  end

  @doc """
  Get user's joined group leaderboard of this month
  """
  @spec api_get_leaderboard_of_partner_this_month(String.t(), String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_this_month(authenticated_user_id, partner_id) do
    api_get_leaderboard_this_month_query(authenticated_user_id)
    |> where([u], u.id in ^members(partner_id))
    |> Repo.all()
  end

  @doc """
  Get overall user's joined group leaderboard
  """
  @spec api_get_leaderboard_of_partner_all_time(String.t(), String.t()) :: [User.t()]
  def api_get_leaderboard_of_partner_all_time(authenticated_user_id, partner_id) do
    api_get_leaderboard_all_time_query(authenticated_user_id)
    |> where([u], u.id in subquery(members(partner_id)))
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
    coalesced_sum = Decimal.from_float(0.0)

    from(
      u in User,
      as: :user,
      left_join: total_kms in "user_agg",
      on: u.id == total_kms.user_id,
      left_lateral_join:
        total_kms_today in subquery(
          from(a in OmegaBravera.Activity.ActivityAccumulator,
            where:
              a.user_id ==
                parent_as(:user).id and
                fragment(
                  "? BETWEEN DATE_TRUNC('day', NOW()) AND DATE_TRUNC('day', NOW() + INTERVAL '1 DAY - 1 SECOND')",
                  a.start_date
                ),
            group_by: a.user_id,
            select: %{user_id: a.user_id, distance: coalesce(sum(a.distance), ^coalesced_sum)}
          )
        ),
      on: total_kms_today.user_id == u.id,
      left_lateral_join:
        total_points_today in subquery(
          from(
            p in Point,
            where:
              p.user_id == parent_as(:user).id and
                fragment(
                  "? BETWEEN DATE_TRUNC('day', NOW()) AND DATE_TRUNC('day', NOW() + INTERVAL '1 DAY - 1 SECOND')",
                  p.inserted_at
                ),
            group_by: p.user_id,
            select: %{
              user_id: p.user_id,
              value: coalesce(sum(p.value), ^coalesced_sum)
            }
          )
        ),
      on: total_points_today.user_id == u.id,
      where: u.id == ^user_id,
      group_by: [u.id, total_kms_today.distance, total_points_today.value, total_kms.distance],
      select: %{
        u
        | total_rewards: 0,
          total_kilometers: coalesce(total_kms.distance, ^coalesced_sum),
          total_kilometers_today: coalesce(total_kms_today.distance, ^coalesced_sum),
          total_points_today: coalesce(total_points_today.value, ^coalesced_sum),
          offer_challenges_map: %{
            live: [],
            expired: [],
            completed: [],
            total: 0
          }
      }
    )
    |> Repo.one()
  end

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
        distance_this_week: fragment("TO_CHAR(?, '999,999 KM')", coalesce(sum(wd.distance), 0)),
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
          from(aa in "user_agg",
            select: %{distance: coalesce(aa.distance, 0), user_id: aa.user_id}
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

    marketing_email_permission =
      from(u in User,
        left_join: permission in assoc(u, :subscribed_email_categories),
        left_join: category in assoc(permission, :category),
        where: category.title == "News, Offers, Updates",
        select: %{user_id: u.id, marketing_email_permission: not is_nil(permission.id)}
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
      left_join: permission in subquery(marketing_email_permission),
      on: permission.user_id == u.id,
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
          friend_referrals: fr.count,
          marketing_email_permission: coalesce(permission.marketing_email_permission, false)
      },
      group_by: [
        u.id,
        d.uuid,
        r.count,
        cr.count,
        td.sum,
        wtd.sum,
        fr.count,
        permission.marketing_email_permission
      ]
    )
  end

  def list_users_for_admin do
    list_users_for_admin_query()
    |> Repo.all()
  end

  @doc """
  Paginate users based on login user type
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

  def get_not_deleted_user!(id) do
    from(u in User, where: u.id == ^id and not is_nil(u.email))
    |> Repo.one!()
  end

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

  def get_user_with_todays_points(user_id, start_date \\ Timex.now()) do
    now = start_date

    from(
      u in User,
      where: u.id == ^user_id,
      left_join: p in Point,
      on:
        p.user_id == ^user_id and p.inserted_at >= ^Timex.beginning_of_day(now) and
          p.inserted_at <= ^Timex.end_of_day(now),
      group_by: u.id,
      select: %{u | todays_points: coalesce(sum(p.value), 0)}
    )
    |> Repo.one!()
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
  Put new email to user and generate verification code to confirm
  """
  @spec update_user_email(User.t(), String.t(), String.t()) :: tuple
  def update_user_email(%User{} = user, password, new_email) do
    cond do
      checkpw(password, user.credential.password_hash) ->
        user
        |> User.update_email_changeset(%{new_email: new_email})
        |> Repo.update()
        |> then(fn result ->
          case result do
            {:ok, updated_user} ->
              Notifier.send_user_confirm_email_change(updated_user)
              result

            _ ->
              result
          end
        end)

      true ->
        {:error, :wrong_password}
    end
  end

  @doc """
  Check if new_email_verification_code is correct
  if correct update email to use the new email
  """
  @spec confirm_update_user_email(User.t(), map) :: tuple
  def confirm_update_user_email(%User{} = user, attrs) do
    user
    |> User.confirm_update_email_changeset(attrs)
    |> Repo.update()
    |> then(fn result ->
      case result do
        {:ok, updated_user} ->
          Notifier.send_user_email_changed(updated_user, user.email)
          result

        _ ->
          result
      end
    end)
  end

  @doc """
  update user password
  """
  @spec update_user_password(User.t(), String.t(), String.t(), String.t()) :: tuple
  def update_user_password(%User{} = user, old_pw, new_pw, new_pw_confirm) do
    cond do
      checkpw(old_pw, user.credential.password_hash) ->
        update_user(user, %{
          credential: %{password: new_pw, password_confirmation: new_pw_confirm}
        })
        |> then(fn result ->
          case result do
            {:ok, updated_user} ->
              Notifier.send_password_changed(updated_user)
              result

            _ ->
              result
          end
        end)

      true ->
        {:error, :wrong_old_password}
    end
  end

  @doc """
  Switch user's sync_type
  """
  @spec switch_sync_type(integer(), atom()) :: {:ok, Strava.t()} | {:error, message: String.t()}
  def switch_sync_type(user_id, :strava) do
    case Accounts.get_user_strava(user_id) do
      nil ->
        {:error, message: "Please connect to Strava before switching"}

      _strava ->
        Accounts.update_user(Accounts.get_user!(user_id), %{sync_type: :strava})
        |> get_sync_update()
    end
  end

  def switch_sync_type(user_id, sync_type),
    do: update_user(Accounts.get_user!(user_id), %{sync_type: sync_type}) |> get_sync_update()

  @spec get_sync_update(tuple()) :: tuple()
  defp get_sync_update({:ok, %{id: user_id}}) do
    result =
      from(
        u in User,
        left_join: s in assoc(u, :strava),
        where: u.id == ^user_id,
        select: %{sync_type: u.sync_type, strava_connected: not is_nil(s.id)}
      )
      |> Repo.one()

    {:ok, result}
  end

  defp get_sync_update(result), do: result

  @doc """
  Enables/disables global push notifications to all of the user's registered devices.
  """
  def enable_push_notifications(%User{} = user, attrs) do
    user
    |> User.push_notifications_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Activates a user's account by setting the user's `email_verified` field to true
  and clearing out the existing token so we have less of a chance of users having
  the same verification code.
  """
  @spec activate_user_email(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def activate_user_email(%User{} = user) do
    changeset =
      User.verify_email_changeset(user, %{email_verified: true, email_activation_token: nil})

    case Repo.update(changeset) do
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
        |> Trackers.Strava.delete_strava_profile_picture_changeset()
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

  def find_admin_user_by_email(email) do
    from(u in AdminUser, where: fragment("lower(?) = ?", u.email, ^email))
    |> Repo.one()
  end

  def find_admin_user_by_reset_token(reset_token) do
    from(u in AdminUser, where: u.reset_token == ^reset_token)
    |> Repo.one()
    |> then(fn admin_user ->
      case admin_user do
        nil ->
          {:error, :user_not_found}

        admin_user ->
          if Tools.expired_2_hours?(admin_user.reset_token_created) do
            {:error, :token_expired}
          else
            {:ok, admin_user}
          end
      end
    end)
  end

  @doc """
  Returns a user in an :ok tuple if user is found by email and correct password.
  Otherwise an error tuple is returned.
  """
  def authenticate_admin_user_by_email_and_pass(email, given_pass) do
    email = String.downcase(email)

    user = find_admin_user_by_email(email)

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

  def send_reset_password_token(%AdminUser{} = admin_user) do
    admin_user
    |> AdminUser.reset_token_changeset()
    |> Repo.update()
    |> then(fn result ->
      case result do
        {:ok, updated_admin} ->
          Notifier.send_password_reset_email(updated_admin)
          result

        _ ->
          result
      end
    end)
  end

  def admin_user_reset_password_changeset(%AdminUser{} = admin_user, attrs \\ %{}),
    do: AdminUser.reset_password_changeset(admin_user, attrs)

  def reset_admin_user_password(%AdminUser{} = admin_user, attrs) do
    admin_user
    |> AdminUser.reset_password_changeset(attrs)
    |> Repo.update()
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

  def get_partner_user(id, preloads \\ []) do
    from(p in PartnerUser, where: p.id == ^id, preload: ^preloads)
    |> Repo.one()
  end

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

  def get_partner_user_by_org_id(org_id) do
    from(p in PartnerUser,
      left_join: om in assoc(p, :organization_members),
      where: om.organization_id == ^org_id,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Mark a partner user as their email verified.
  """
  @spec verify_partner_user_email(PartnerUser.t()) :: {:ok, PartnerUser.t()}
  def verify_partner_user_email(%PartnerUser{} = partner_user) do
    case update_partner_user(partner_user, %{email_verified: true}) do
      {:ok, %{id: partner_user_id}} = result ->
        %{id: partner_user_id}
        |> OmegaBravera.Accounts.Jobs.PartnerUserVerified.new()
        |> Oban.insert()

        result

      result ->
        result
    end
  end

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
  Get organization by partner_user_id
  """
  def get_organization_by_partner_user!(partner_user_id) do
    from(o in Organization,
      left_join: om in assoc(o, :organization_members),
      where: om.partner_user_id == ^partner_user_id,
      limit: 1
    )
    |> Repo.one!()
  end

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

  def update_organization_block_on(%Organization{} = organization, attrs) do
    organization
    |> Organization.block_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Block or unblock an organization's access to admin panel
  """
  def block_or_unblock_org(%Organization{blocked_on: nil} = organization),
    do: update_organization_block_on(organization, %{blocked_on: Timex.now()})

  def block_or_unblock_org(%Organization{} = organization),
    do: update_organization_block_on(organization, %{blocked_on: nil})

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
  List new members joined yesterday
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
  List new group members of org
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
  Create friend request
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
  Accept friend request
  """
  @spec accept_friend_request(Friend.t()) :: {:ok, Friend.t()} | {:error, %Ecto.Changeset{}}
  def accept_friend_request(%Friend{} = friend) do
    friend
    |> Friend.accept_changeset(%{})
    |> Repo.update()
    |> notify_user()
    |> broadcast_friend_chat()
  end

  @spec notify_user(tuple()) :: tuple()
  defp notify_user({:ok, %Friend{} = friend} = tuple) do
    OmegaBravera.Notifications.Jobs.NotifyNewFriend.new(friend)
    |> Oban.insert()

    tuple
  end

  defp notify_user(tuple), do: tuple

  defp broadcast_friend_chat(
         {:ok, %{receiver_id: receiver_id, requester_id: requester_id}} = result
       ) do
    @endpoint.broadcast(@user_channel.user_channel(receiver_id), "friend_chat", %{
      id: requester_id
    })

    @endpoint.broadcast(@user_channel.user_channel(requester_id), "friend_chat", %{
      id: receiver_id
    })

    result
  end

  defp broadcast_friend_chat(result), do: result

  defp broadcast_user_unfriended(
         {:ok, %{receiver_id: receiver_id, requester_id: requester_id}} = result
       ) do
    :ok =
      @endpoint.broadcast(@user_channel.user_channel(receiver_id), "unfriended", %{
        id: requester_id
      })

    :ok =
      @endpoint.broadcast(@user_channel.user_channel(requester_id), "unfriended", %{
        id: receiver_id
      })

    result
  end

  defp broadcast_user_unfriended(result), do: result

  @doc """
  Reject friend request
  """
  @spec reject_friend_request(Friend.t()) :: {:ok, Friend.t()} | {:error, %Ecto.Changeset{}}
  def reject_friend_request(%Friend{} = friend), do: Repo.delete(friend)

  @doc """
  Remove the friendship between 2 users
  """
  @spec remove_friendship(integer(), integer()) ::
          {:ok, Friend.t()} | {:error, Ecto.Changeset.t()}
  def remove_friendship(friend_user_id, user_id) do
    find_existing_friend(friend_user_id, user_id)
    |> Repo.delete()
    |> broadcast_user_unfriended()
  end

  @doc """
  Mute or unmute receiver's notification
  """
  def mute_receiver_notification(friend, attrs \\ %{}) do
    friend
    |> Friend.mute_receiver_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Mute or unmute requester's notification
  """
  def mute_requester_notification(friend, attrs \\ %{}) do
    friend
    |> Friend.mute_requester_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get friend by receiver_id and requester_id
  """
  @spec get_friend_by_receiver_id_requester_id(integer(), integer()) :: Friend.t() | nil
  def get_friend_by_receiver_id_requester_id(receiver_id, requester_id) do
    from(f in Friend, where: f.receiver_id == ^receiver_id and f.requester_id == ^requester_id)
    |> Repo.one()
  end

  @doc """
  List and search accepted friends
  """
  @spec list_accepted_friends(integer(), String.t(), map()) :: [User.t()]
  def list_accepted_friends(user_id, keyword, pagination_args) do
    search = "%#{keyword}%"

    from(u in User,
      left_join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      where:
        f.status == :accepted and (f.receiver_id == ^user_id or f.requester_id == ^user_id) and
          u.id != ^user_id and not is_nil(u.email) and ilike(u.username, ^search),
      order_by: [u.username]
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  List friend requests
  """
  @spec list_friend_requests(integer()) :: [Friend.t()]
  def list_friend_requests(user_id) do
    from(f in Friend,
      left_join: requester in assoc(f, :requester),
      where: f.status == :pending and f.receiver_id == ^user_id and not is_nil(requester.email)
    )
    |> Repo.all()
  end

  @doc """
  Search and list users that can send friend request to
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
          (is_nil(f.id) or f.status != :accepted) and not is_nil(u.email),
      order_by: u.username,
      select: %{
        u
        | friend_status: fragment("CASE WHEN ? THEN 'stranger' ELSE 'pending' END", is_nil(f.id))
      }
    )
    |> Relay.Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  Get information of the given user for comparison
  """
  @spec get_user_for_comparison(integer()) :: User.t()
  def get_user_for_comparison(user_id) do
    now = Timex.now()
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)
    seven_days_ago = Timex.shift(now, days: -7)
    thirty_days_ago = Timex.shift(now, days: -30)

    from(u in User,
      left_join: ttd in subquery(activity_query(beginning_of_day, end_of_day)),
      on: ttd.user_id == u.id,
      left_join: wtd in subquery(activity_query(seven_days_ago, now)),
      on: wtd.user_id == u.id,
      left_join: mtd in subquery(activity_query(thirty_days_ago, now)),
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
  Get only today's distance for a certain user.
  """
  @spec get_user_todays_distance(integer(), integer()) :: User.t()
  def get_user_todays_distance(user_id, user_id) do
    now = Timex.now()
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)

    from(u in User,
      left_join: ttd in subquery(activity_query(beginning_of_day, end_of_day)),
      on: ttd.user_id == u.id,
      where: u.id == ^user_id,
      group_by: [u.id, ttd.distance],
      select: %{
        u
        | total_kilometers_today: coalesce(ttd.distance, 0)
      }
    )
    |> Repo.one()
  end

  def get_user_todays_distance(user_id, current_user_id) do
    now = Timex.now()
    beginning_of_day = Timex.beginning_of_day(now)
    end_of_day = Timex.end_of_day(now)

    from(u in User,
      left_join: ttd in subquery(activity_query(beginning_of_day, end_of_day)),
      on: ttd.user_id == u.id,
      left_join: f in Friend,
      on:
        (f.receiver_id == u.id and f.requester_id == ^current_user_id) or
          (f.requester_id == u.id and f.receiver_id == ^current_user_id),
      where: u.id == ^user_id,
      group_by: [u.id, ttd.distance, f.id],
      select: %{
        u
        | total_kilometers_today: coalesce(ttd.distance, 0),
          is_friend:
            fragment("CASE WHEN ? THEN 'f' ELSE 't' END", is_nil(f.id) or f.status == :pending),
          friend_status:
            fragment(
              "CASE WHEN ? THEN 'stranger' WHEN ? THEN 'pending' ELSE 'accepted' END",
              is_nil(f.id),
              f.status == :pending
            )
      }
    )
    |> Repo.one()
    # hack to go from string to atom
    |> Map.update!(:friend_status, &String.to_existing_atom/1)
  end

  @doc """
  List all friends with chat messages
  """
  @spec list_accepted_friends_with_chat_messages(integer(), integer()) :: [User.t()]
  def list_accepted_friends_with_chat_messages(user_id, limit \\ 10) do
    from(u in User,
      as: :user,
      left_join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      left_join: message in PrivateChatMessage,
      on:
        (message.from_user_id == u.id and message.to_user_id == ^user_id) or
          (message.from_user_id == ^user_id and message.to_user_id == u.id),
      left_lateral_join:
        pm in subquery(
          from(private_chat in PrivateChatMessage,
            where:
              (private_chat.from_user_id == parent_as(:user).id and
                 private_chat.to_user_id == ^user_id) or
                (private_chat.from_user_id == ^user_id and
                   private_chat.to_user_id == parent_as(:user).id),
            order_by: [desc: :inserted_at],
            limit: ^limit
          )
        ),
      on:
        (pm.from_user_id == u.id and pm.to_user_id == ^user_id) or
          (pm.from_user_id == ^user_id and pm.to_user_id == u.id),
      where:
        f.status == :accepted and (f.receiver_id == ^user_id or f.requester_id == ^user_id) and
          u.id != ^user_id and not is_nil(u.email),
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
  Get friend with chat messages
  """
  def get_friend_with_chat_messages(user_id, to_user_id, limit \\ 10) do
    from(u in User,
      as: :user,
      left_join: f in Friend,
      on: f.receiver_id == u.id or f.requester_id == u.id,
      left_join: message in PrivateChatMessage,
      on:
        (message.from_user_id == u.id and message.to_user_id == ^user_id) or
          (message.from_user_id == ^user_id and message.to_user_id == u.id),
      left_lateral_join:
        pm in subquery(
          from(private_chat in PrivateChatMessage,
            where:
              (private_chat.from_user_id == parent_as(:user).id and
                 private_chat.to_user_id == ^user_id) or
                (private_chat.from_user_id == ^user_id and
                   private_chat.to_user_id == parent_as(:user).id),
            order_by: [desc: :inserted_at],
            limit: ^limit
          )
        ),
      on:
        (pm.from_user_id == u.id and pm.to_user_id == ^user_id) or
          (pm.from_user_id == ^user_id and pm.to_user_id == u.id),
      where:
        f.status == :accepted and
          ((f.receiver_id == ^user_id and f.requester_id == ^to_user_id) or
             (f.requester_id == ^user_id and f.receiver_id == ^to_user_id)) and
          u.id != ^user_id and u.id == ^to_user_id and not is_nil(u.email),
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
    |> Repo.one()
  end

  @doc """
  Create new private_chat_message
  """
  @spec create_private_chat_message(map()) ::
          {:ok, PrivateChatMessage.t()} | {:error, Ecto.Changeset.t()}
  def create_private_chat_message(attrs \\ %{}) do
    %PrivateChatMessage{}
    |> PrivateChatMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update private message
  """
  @spec update_private_message(PrivateChatMessage.t(), map()) ::
          {:ok, PrivateChatMessage.t()} | {:error, Ecto.Changeset.t()}
  def update_private_message(message, attrs \\ %{}) do
    message
    |> PrivateChatMessage.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete private message
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
