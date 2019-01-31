defmodule OmegaBravera.Challenges do
  @moduledoc """
  The Challenges context.
  """

  import Ecto.Query, warn: false

  alias OmegaBravera.Repo
  alias OmegaBravera.Challenges.{NGOChal, Activity, Team, TeamMembers}
  alias OmegaBravera.Fundraisers.NGO

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

  def latest_activities(%NGOChal{} = challenge, limit \\ nil, preloads \\ [user: [:strava]]) do
    query =
      from(activity in Activity,
        where: activity.challenge_id == ^challenge.id,
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

  def get_user_ngo_chals(user_id, preloads \\ [:ngo]) do
    from(
      nc in NGOChal,
      where: nc.user_id == ^user_id,
      left_join: a in Activity,
      on: nc.id == a.challenge_id,
      preload: ^preloads,
      order_by: [desc: :start_date],
      group_by: nc.id,
      select: %{
        nc
        | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", a.distance),
          start_date: fragment("? at time zone 'utc'", nc.start_date),
          end_date: fragment("? at time zone 'utc'", nc.end_date)
      }
    )
    |> Repo.all()
  end

  def get_user_ngo_chals_ids(user_id) do
    from(
      c in NGOChal,
      where: c.user_id == ^user_id,
      select: c.id
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
        left_join: a in Activity,
        on: nc.id == a.challenge_id,
        where: nc.slug == ^slug and n.slug == ^ngo_slug,
        preload: ^preloads,
        group_by: nc.id,
        select: %{
          nc
          | distance_covered: fragment("round(sum(coalesce(?, 0)), 1)", a.distance),
            start_date: fragment("? at time zone 'utc'", nc.start_date),
            end_date: fragment("? at time zone 'utc'", nc.end_date)
        }
      )

    Repo.one(query)
  end

  def get_ngo_milestone_ngo_chals(%NGO{} = ngo) do
    from(nc in NGOChal,
      where: nc.ngo_id == ^ngo.id and nc.type == "PER_MILESTONE",
      join: user in assoc(nc, :user),
      join: strava in assoc(user, :strava),
      preload: [user: {user, strava: strava}]
    )
    |> Repo.all()
  end

  def get_ngo_km_ngo_chals(%NGO{} = ngo) do
    from(nc in NGOChal,
      where: nc.ngo_id == ^ngo.id and nc.type == "PER_KM",
      join: user in assoc(nc, :user),
      join: strava in assoc(user, :strava),
      preload: [user: {user, strava: strava}]
    )
    |> Repo.all()
  end

  def get_expired_km_challenges() do
    now = Timex.now()

    from(
      nc in NGOChal,
      where: nc.type == "PER_KM" and (nc.status == "complete" or ^now >= nc.end_date),
      join: donations in assoc(nc, :donations),
      on: donations.ngo_chal_id == nc.id and donations.status == "pending",
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
        select: sum(donations.amount)
      )
      |> Repo.one()

    case km_pledges do
      nil -> Decimal.new(0)
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

  def get_activity_types, do: NGOChal.activity_types()

  def get_number_of_activities_by_user(user_id) do
    from(a in Activity, where: a.user_id == ^user_id, select: count(a.id))
    |> Repo.one()
  end

  def get_total_distance_by_user(user_id) do
    from(a in Activity, where: a.user_id == ^user_id, select: sum(a.distance))
    |> Repo.one()
  end

  def amount_of_activities() do
    from(a in Activity, select: count(a.id))
    |> Repo.one()
  end

  def total_actual_distance do
    from(a in Activity, select: sum(a.distance))
    |> Repo.one()
  end

  def get_distances, do: NGOChal.distances_available()

  def total_distance_target do
    from(c in NGOChal, select: sum(c.distance_target))
    |> Repo.one()
  end

  @doc """
  Creates a ngo_chal.

  ## Examples

      iex> create_ngo_chal(%{field: value})
      {:ok, %NGOChal{}}

      iex> create_ngo_chal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ngo_chal(%NGOChal{} = chal, %NGO{} = ngo, attrs \\ %{}) do
    chal
    |> NGOChal.create_changeset(ngo, attrs)
    |> Repo.insert()
  end

  def create_ngo_chal_with_team(%NGOChal{} = chal, %NGO{} = ngo, attrs \\ %{}) do
    chal
    |> NGOChal.create_with_team_changeset(ngo, attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of ngo_chals.

  ## Examples

      iex> list_ngo_chals()
      [%NGOChal{}, ...]

  """
  def list_ngo_chals(preloads \\ [:user, :ngo, :donations]) do
    from(nc in NGOChal,
      left_join: a in Activity,
      on: nc.id == a.challenge_id,
      preload: ^preloads,
      group_by: nc.id,
      order_by: [desc: nc.id],
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", a.distance)}
    )
    |> Repo.all()
  end

  def list_active_ngo_chals(preloads \\ [:user, :ngo, :donations]) do
    from(nc in NGOChal,
      left_join: a in Activity,
      on: nc.id == a.challenge_id and nc.status == "active",
      preload: ^preloads,
      group_by: nc.id,
      order_by: [desc: nc.id],
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", a.distance)}
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

  @doc """
  Gets a single ngo_chal.

  Raises `Ecto.NoResultsError` if the Ngo chal does not exist.

  ## Examples

      iex> get_ngo_chal!(123)
      %NGOChal{}

      iex> get_ngo_chal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ngo_chal!(id) do
    from(nc in NGOChal,
      left_join: a in Activity,
      on: nc.id == a.challenge_id,
      preload: [:donations],
      group_by: nc.id,
      select: %{nc | distance_covered: fragment("sum(coalesce(?,0))", a.distance)},
      where: nc.id == ^id
    )
    |> Repo.one!()
  end

  @doc """
  Updates a ngo_chal.

  ## Examples

      iex> update_ngo_chal(ngo_chal, %{field: new_value})
      {:ok, %NGOChal{}}

      iex> update_ngo_chal(ngo_chal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ngo_chal(%NGOChal{} = ngo_chal, attrs) do
    ngo_chal
    |> NGOChal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a NGOChal.

  ## Examples

      iex> delete_ngo_chal(ngo_chal)
      {:ok, %NGOChal{}}

      iex> delete_ngo_chal(ngo_chal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ngo_chal(%NGOChal{} = ngo_chal) do
    Repo.delete(ngo_chal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ngo_chal changes.

  ## Examples

      iex> change_ngo_chal(ngo_chal)
      %Ecto.Changeset{source: %NGOChal{}}

  """
  def change_ngo_chal(%NGOChal{} = ngo_chal) do
    NGOChal.changeset(ngo_chal, %{})
  end

  def get_total_challenge_days() do
    from(c in NGOChal, select: sum(fragment("?::date - ?::date", c.end_date, c.start_date)))
    |> Repo.one()
  end

  @doc """
  Returns the list of teams.

  ## Examples

      iex> list_teams()
      [%Team{}, ...]

  """
  def list_teams do
    Repo.all(Team)
  end

  @doc """
  Gets a single team.

  Raises `Ecto.NoResultsError` if the Team does not exist.

  ## Examples

      iex> get_team!(123)
      %Team{}

      iex> get_team!(456)
      ** (Ecto.NoResultsError)

  """
  def get_team!(id), do: Repo.get!(Team, id)

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(%{field: value})
      {:ok, %Team{}}

      iex> create_team(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(team, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(team, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Team.

  ## Examples

      iex> delete_team(team)
      {:ok, %Team{}}

      iex> delete_team(team)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team(team)
      %Ecto.Changeset{source: %Team{}}

  """
  def change_team(%Team{} = team) do
    Team.changeset(team, %{})
  end

  def add_user_to_team(attrs \\ %{}) do
    %TeamMembers{}
    |> TeamMembers.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def available_challenge_types, do: NGOChal.challenge_type_options()
end
