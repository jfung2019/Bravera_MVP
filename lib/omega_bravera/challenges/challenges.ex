defmodule OmegaBravera.Challenges do
  @moduledoc """
  The Challenges context.
  """

  import Ecto.Query, warn: false

  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.{
    NGOChal,
    Team,
    TeamMembers,
    TeamInvitations,
    NgoChallengeActivitiesM2m
  }

  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Activity.ActivityAccumulator

  use Timex

  def inactive_for_five_days() do
    query =
      from(challenge in NGOChal,
        where: challenge.status == "active",
        where: challenge.last_activity_received <= fragment("now() - interval '5 days'"),
        where: challenge.participant_notified_of_inactivity == false
      )

    Repo.all(query)
  end

  def inactive_for_seven_days() do
    query =
      from(challenge in NGOChal,
        where: challenge.status == "active",
        where: challenge.last_activity_received <= fragment("now() - interval '7 days'"),
        where: challenge.donor_notified_of_inactivity == false
      )

    Repo.all(query)
  end

  def get_team_member_activity_totals(challenge_id, users_list \\ []) do
    user_ids = Enum.map(users_list, & &1.id)

    team_activities =
      from(
        activity_relation in NgoChallengeActivitiesM2m,
        where: activity_relation.challenge_id == ^challenge_id,
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

  def latest_activities(%NGOChal{} = challenge, limit \\ nil, preloads \\ [user: [:strava]]) do
    query =
      from(
        activity in ActivityAccumulator,
        join: activity_relation in NgoChallengeActivitiesM2m,
        on: activity.id == activity_relation.activity_id,
        where: activity_relation.challenge_id == ^challenge.id,
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

  def get_user_solo_ngo_chals(user_id, preloads \\ [:ngo]) do
    from(
      nc in NGOChal,
      where: nc.user_id == ^user_id and nc.has_team == false,
      left_join: a in NgoChallengeActivitiesM2m,
      on: nc.id == a.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      on: nc.id == a.challenge_id,
      preload: ^preloads,
      order_by: [desc: :start_date],
      group_by: nc.id,
      select: %{
        nc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance),
          start_date: fragment("? at time zone 'utc'", nc.start_date),
          end_date: fragment("? at time zone 'utc'", nc.end_date)
      }
    )
    |> Repo.all()
  end

  def get_user_team_ngo_chals(user_id, preloads \\ [:ngo]) do
    from(
      nc in NGOChal,
      where: nc.user_id == ^user_id and nc.has_team == true,
      left_join: a in NgoChallengeActivitiesM2m,
      on: nc.id == a.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      preload: ^preloads,
      order_by: [desc: :start_date],
      group_by: nc.id,
      select: %{
        nc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance),
          start_date: fragment("? at time zone 'utc'", nc.start_date),
          end_date: fragment("? at time zone 'utc'", nc.end_date)
      }
    )
    |> Repo.all()
  end

  def get_supporters_num(user_id) do
    from(nc in NGOChal,
      where: nc.user_id == ^user_id,
      left_join: d in Donation,
      on: d.ngo_chal_id == nc.id,
      select: count(d.donor_id, :distinct)
    )
    |> Repo.one()
  end

  # No longer used.
  # def get_user_challenges_totals(user_id) do
  #   challenges_distance_covered =
  #     from(
  #       nc in NGOChal,
  #       where: nc.user_id == ^user_id,
  #       left_join: a in NgoChallengeActivitiesM2m,
  #       on: nc.id == a.challenge_id,
  #       left_join: ac in ActivityAccumulator,
  #       on: a.activity_id == ac.id,
  #       group_by: [nc.id],
  #       select: %{
  #         challenge_id: nc.id,
  #         distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance)
  #       }
  #     )

  #   from(nc in NGOChal,
  #     where: nc.user_id == ^user_id,
  #     left_join: d in assoc(nc, :donations),
  #     join: activity in subquery(challenges_distance_covered),
  #     on: activity.challenge_id == nc.id,
  #     select: %{
  #       total_pledged:
  #         fragment(
  #           "
  #         CASE
  #           WHEN (? = 'pending' AND ? = 'PER_KM') THEN ? * ?
  #           WHEN (? = 'charged' AND ? = 'PER_KM') THEN ?
  #           WHEN (? = 'pending' AND ? = 'PER_MILESTONE') THEN ?
  #           WHEN (? = 'charged' AND ? = 'PER_MILESTONE') THEN ?
  #           ELSE 0
  #         END",
  #           d.status,
  #           nc.type,
  #           d.amount,
  #           activity.distance_covered,
  #           d.status,
  #           nc.type,
  #           d.charged_amount,
  #           d.status,
  #           nc.type,
  #           d.amount,
  #           d.status,
  #           nc.type,
  #           d.charged_amount
  #         ),
  #       total_secured: fragment("
  #         CASE
  #           WHEN (? = 'charged' AND ? = 'PER_KM') THEN ?
  #           WHEN (? = 'charged' AND ? = 'PER_MILESTONE') THEN ?
  #           ELSE 0
  #         END", d.status, nc.type, d.charged_amount, d.status, nc.type, d.charged_amount),
  #       currency: fragment("LOWER(?)", nc.default_currency)
  #     }
  #   )
  #   |> Repo.all()
  #   |> user_challenges_donations_totals_strings()
  # end

  # defp user_challenges_donations_totals_strings(totals) do
  #   currencies = %{
  #     "hkd" => Decimal.new(0),
  #     "krw" => Decimal.new(0),
  #     "sgd" => Decimal.new(0),
  #     "myr" => Decimal.new(0),
  #     "usd" => Decimal.new(0),
  #     "gbp" => Decimal.new(0)
  #   }

  #   total_pledged_map =
  #     Enum.reduce(totals, currencies, fn d, acc ->
  #       total_pledged = d[:total_pledged]

  #       case total_pledged do
  #         nil ->
  #           acc

  #         _ ->
  #           Map.update(acc, d[:currency], total_pledged, fn sum ->
  #             Decimal.add(sum, total_pledged)
  #           end)
  #       end
  #     end)
  #     |> Enum.filter(fn {_currency, total} -> Decimal.cmp(total, Decimal.new(0)) == :gt end)
  #     |> Enum.into(%{})

  #   total_secured_map =
  #     Enum.reduce(totals, currencies, fn d, acc ->
  #       total_secured = d[:total_secured]

  #       case total_secured do
  #         nil ->
  #           acc

  #         _ ->
  #           Map.update(acc, d[:currency], total_secured, fn sum ->
  #             Decimal.add(sum, total_secured)
  #           end)
  #       end
  #     end)
  #     |> Enum.filter(fn {_currency, total} -> Decimal.cmp(total, Decimal.new(0)) == :gt end)
  #     |> Enum.into(%{})

  #   %{
  #     total_pledged: total_to_string(total_pledged_map),
  #     total_secured: total_to_string(total_secured_map)
  #   }
  # end

  # defp total_to_string(total_map) do
  #   Enum.reduce(total_map, "", fn
  #     el, acc ->
  #       "#{String.upcase(elem(el, 0))}: #{elem(el, 1)} " <> acc
  #   end)
  # end

  def get_user_team_membership(user_id) do
    from(
      tm in TeamMembers,
      where: tm.user_id == ^user_id,
      join: team in Team,
      on: tm.team_id == team.id,
      join: challenge in NGOChal,
      on: team.challenge_id == challenge.id,
      left_join: activity in NgoChallengeActivitiesM2m,
      on: challenge.id == activity.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: activity.activity_id == ac.id,
      preload: [team: {team, challenge: {challenge, :ngo}}]
    )
    |> Repo.all()
  end

  def get_user_active_ngo_chals(user_id) do
    query =
      from(nc in NGOChal,
        where: nc.user_id == ^user_id,
        where: nc.status == "active"
      )

    Repo.all(query)
  end

  def get_one_user_active_chal(user_id) do
    query =
      from(nc in NGOChal,
        where: nc.user_id == ^user_id,
        where: nc.status == "active",
        order_by: nc.inserted_at,
        limit: 1
      )

    Repo.one(query)
  end

  def get_ngo_chal_by_slugs(ngo_slug, slug, preloads \\ [:ngo]) do
    query =
      from(nc in NGOChal,
        join: n in NGO,
        on: nc.ngo_id == n.id,
        left_join: a in NgoChallengeActivitiesM2m,
        on: nc.id == a.challenge_id,
        left_join: ac in ActivityAccumulator,
        on: a.activity_id == ac.id,
        where: nc.slug == ^slug and n.slug == ^ngo_slug,
        preload: ^preloads,
        group_by: nc.id,
        select: %{
          nc
          | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", ac.distance),
            start_date: fragment("? at time zone 'utc'", nc.start_date),
            end_date: fragment("? at time zone 'utc'", nc.end_date)
        }
      )

    Repo.one(query)
  end

  def get_ngo_milestone_ngo_chals(%NGO{} = ngo) do
    from(nc in NGOChal,
      where: nc.ngo_id == ^ngo.id and nc.type == "PER_MILESTONE",
      preload: [user: [:strava], team: [users: [:strava]]]
    )
    |> Repo.all()
  end

  def get_ngo_km_ngo_chals(%NGO{} = ngo) do
    from(nc in NGOChal,
      where: nc.ngo_id == ^ngo.id and nc.type == "PER_KM",
      preload: [user: [:strava], team: [users: [:strava]]]
    )
    |> Repo.all()
  end

  def get_expired_km_challenges() do
    now = Timex.now()

    from(
      nc in NGOChal,
      where: nc.type == "PER_KM" and (nc.status == "complete" or ^now >= nc.end_date),
      join: donations in assoc(nc, :donations),
      on:
        donations.ngo_chal_id == nc.id and donations.status == "pending" and
          donations.type == "km",
      preload: [donations: donations]
    )
    |> Repo.all()
  end

  def get_per_km_challenge_total_pledges(slug) do
    km_pledges =
      from(
        nc in NGOChal,
        where: nc.type == "PER_KM" and nc.slug == ^slug,
        left_join: donations in assoc(nc, :donations),
        on: donations.ngo_chal_id == nc.id,
        select:
          {fragment("SUM(CASE ? WHEN 'km' THEN ? ELSE 0 END)", donations.type, donations.amount),
           fragment(
             "SUM(CASE ? WHEN 'follow_on' THEN ? ELSE 0 END)",
             donations.type,
             donations.charged_amount
           )}
      )
      |> Repo.one()

    case km_pledges do
      {nil, _} -> {Decimal.new(0), elem(km_pledges, 1)}
      {_, nil} -> {elem(km_pledges, 0), Decimal.new(0)}
      {nil, nil} -> {Decimal.new(0), Decimal.new(0)}
      _ -> km_pledges
    end
  end

  def get_per_km_challenge_total_secured(slug) do
    from(
      nc in NGOChal,
      where: nc.type == "PER_KM" and nc.slug == ^slug,
      left_join: donations in assoc(nc, :donations),
      on: donations.ngo_chal_id == nc.id and donations.status == "charged",
      select: sum(donations.charged_amount)
    )
    |> Repo.one()
  end

  def get_number_of_activities_by_user(user_id) do
    from(a in ActivityAccumulator, where: a.user_id == ^user_id, select: count(a.id))
    |> Repo.one()
  end

  def get_total_distance_by_user(user_id) do
    from(a in ActivityAccumulator, where: a.user_id == ^user_id, select: sum(a.distance))
    |> Repo.one()
  end

  def amount_of_activities() do
    from(a in ActivityAccumulator, select: count(a.id))
    |> Repo.one()
  end

  def total_actual_distance do
    from(a in ActivityAccumulator, select: sum(a.distance))
    |> Repo.one()
  end

  def total_distance_target do
    from(c in NGOChal, select: sum(c.distance_target))
    |> Repo.one()
  end

  def create_ngo_chal(%NGOChal{} = chal, %NGO{} = ngo, %User{} = user, attrs \\ %{}) do
    chal
    |> NGOChal.create_changeset(ngo, user, attrs)
    |> Repo.insert()
  end

  def create_ngo_chal_with_team(%NGOChal{} = chal, %NGO{} = ngo, %User{} = user, attrs \\ %{}) do
    chal
    |> NGOChal.create_with_team_changeset(ngo, user, attrs)
    |> Repo.insert()
  end

  def list_ngo_chals(preloads \\ [:user, :ngo, :donations]) do
    from(nc in NGOChal,
      left_join: a in NgoChallengeActivitiesM2m,
      on: nc.id == a.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      on: nc.id == a.challenge_id,
      preload: ^preloads,
      group_by: nc.id,
      order_by: [desc: nc.id],
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", ac.distance)}
    )
    |> Repo.all()
  end

  def list_active_ngo_chals(preloads \\ [:user, :ngo, :donations]) do
    from(nc in NGOChal,
      left_join: a in NgoChallengeActivitiesM2m,
      on: nc.id == a.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      on: nc.id == a.challenge_id and nc.status == "active",
      preload: ^preloads,
      group_by: nc.id,
      order_by: [desc: nc.id],
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", ac.distance)}
    )
    |> Repo.all()
  end

  def get_live_ngo_chals() do
    from(
      nc in NGOChal,
      where: nc.status == "pre_registration" and nc.start_date < ^Timex.now()
    )
    |> Repo.all()
  end

  def get_ngo_chal!(id) do
    from(nc in NGOChal,
      left_join: a in NgoChallengeActivitiesM2m,
      on: nc.id == a.challenge_id,
      left_join: ac in ActivityAccumulator,
      on: a.activity_id == ac.id,
      on: nc.id == a.challenge_id,
      preload: [:donations],
      group_by: nc.id,
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", ac.distance)},
      where: nc.id == ^id
    )
    |> Repo.one!()
  end

  def update_ngo_chal(%NGOChal{} = ngo_chal, %User{} = user, attrs) do
    ngo_chal
    |> NGOChal.update_changeset(user, attrs)
    |> Repo.update()
  end

  def delete_ngo_chal(%NGOChal{} = ngo_chal) do
    Repo.delete(ngo_chal)
  end

  def change_ngo_chal(%NGOChal{} = ngo_chal, %User{} = user) do
    NGOChal.changeset(ngo_chal, user, %{})
  end

  def get_total_challenge_days() do
    from(c in NGOChal, select: sum(fragment("?::date - ?::date", c.end_date, c.start_date)))
    |> Repo.one()
  end

  def list_teams do
    Repo.all(Team)
  end

  def get_team!(id), do: Repo.get!(Team, id)

  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  def change_team(%Team{} = team) do
    Team.changeset(team, %{})
  end

  def add_user_to_team(attrs \\ %{}) do
    %TeamMembers{}
    |> TeamMembers.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def get_team_member_accepted_invitation(%{team_id: team_id, status: status, email: email}) do
    from(
      invitation in TeamInvitations,
      where:
        invitation.email == ^email and invitation.team_id == ^team_id and
          invitation.status == ^status
    )
    |> Repo.one()
  end

  def get_team_member_invitation_by_token(token) do
    from(
      invitation in TeamInvitations,
      where: invitation.token == ^token
    )
    |> Repo.one()
  end

  def resend_team_member_invitation(%TeamInvitations{} = team_invitation) do
    team_invitation
    |> TeamInvitations.invitation_resent_changeset()
    |> Repo.update()
  end

  def create_team_member_invitation(team, attrs \\ %{}) do
    %TeamInvitations{}
    |> TeamInvitations.changeset(team, attrs)
    |> Repo.insert()
  end

  def cancel_team_member_invitation(%TeamInvitations{} = team_invitation) do
    team_invitation
    |> TeamInvitations.invitation_cancelled_changeset()
    |> Repo.update()
  end

  def accepted_team_member_invitation(%TeamInvitations{} = team_invitation) do
    team_invitation
    |> TeamInvitations.invitation_accepted_changeset()
    |> Repo.update()
  end

  def kick_team_member(
        team_member,
        %NGOChal{
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
      otm in TeamMembers,
      where: otm.user_id == ^user_id and otm.team_id == ^team_id,
      preload: [:user]
    )
    |> Repo.one()
  end

  def create_ngo_challenge_activity_m2m(
        %ActivityAccumulator{} = activity,
        %NGOChal{} = challenge
      ),
      do: NgoChallengeActivitiesM2m.changeset(activity, challenge) |> Repo.insert()
end
