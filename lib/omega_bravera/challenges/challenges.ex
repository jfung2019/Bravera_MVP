defmodule OmegaBravera.Challenges do
  @moduledoc """
  The Challenges context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.{NGOChal, Team}
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Fundraisers.NGO

  def get_user_ngo_chals(user_id) do
    query = from nc in NGOChal, where: nc.user_id == ^user_id
    Repo.all(query)
  end

  def get_user_active_ngo_chals(user_id) do
    query = from nc in NGOChal,
      where: nc.user_id == ^user_id,
      where: nc.status == "Active"

    Repo.all(query)
  end

  def get_one_user_active_chal(user_id) do
    query = from nc in NGOChal,
      where: nc.user_id == ^user_id,
      where: nc.status == "Active",
      order_by: nc.inserted_at,
      limit: 1

    Repo.one(query)
  end

  def get_ngo_chal_by_slug(slug) do
    query = from nc in NGOChal,
      where: nc.slug == ^slug

    Repo.one(query)
  end

  def get_ngo_ngo_chals(ngo_id, order_by) do

    query = from nc in NGOChal,
          where: nc.ngo_id == ^ngo_id,
          join: u in User, where: u.id == nc.user_id

    query = from [nc, u] in query,
      select: { nc.id, nc.total_pledged, nc.total_secured, u.firstname, u.lastname}

    case order_by do
      "total_pledged" ->
        query = from q in query, order_by: [desc: q.total_pledged]

        query
        |> Repo.all
      "total_secured" ->
        query = from q in query, order_by: [desc: q.total_secured]

        query
        |> Repo.all
    end
  end
  @doc """
  Creates a ngo_chal.

  ## Examples

      iex> create_ngo_chal(%{field: value})
      {:ok, %NGOChal{}}

      iex> create_ngo_chal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ngo_chal(%NGOChal{} = chal, attrs \\ %{}) do

    chal
    |> NGOChal.changeset(attrs)
    |> Repo.insert()
  end

  def insert_ngo_chal(params, ngo_id, user_id, slug, start_date, end_date) do
    %NGOChal{ngo_id: ngo_id, user_id: user_id, slug: slug, start_date: start_date, end_date: end_date}
    |> NGOChal.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Returns the list of ngo_chals.

  ## Examples

      iex> list_ngo_chals()
      [%NGOChal{}, ...]

  """
  def list_ngo_chals do
    Repo.all(NGOChal)
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
  def get_ngo_chal!(id), do: Repo.get!(NGOChal, id)



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
    |> Team.changeset(attrs)
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
end
