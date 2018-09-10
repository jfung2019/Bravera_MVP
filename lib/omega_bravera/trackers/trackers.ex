defmodule OmegaBravera.Trackers do
  @moduledoc """
  The Trackers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Challenges.NGOChal

  def create_or_update_tracker(%{id: user_id}, %{token: token} = changeset) do
    case Repo.get_by(Strava, user_id: user_id) do
      nil ->
        create_strava(user_id, changeset)
      strava ->
        unless strava.token == token do #is this some convoluted way of saying to update it when the token's been refreshed?
          update_strava(strava, changeset)
        end
    end
  end

  def get_strava_ngo_chals(athlete_id) do
  query = from s in Strava,
    where: s.athlete_id == ^athlete_id,
    join: nc in NGOChal, where: s.user_id == nc.user_id and nc.status == "Active",
    select: {
      nc.id,
      s.token
    }

    query
    |> Repo.all()
  end

  @doc """
  Returns the list of stravas.

  ## Examples

      iex> list_stravas()
      [%Strava{}, ...]

  """
  def list_stravas do
    Repo.all(Strava)
  end

  @doc """
  Gets a single strava.

  Raises `Ecto.NoResultsError` if the Strava does not exist.

  ## Examples

      iex> get_strava!(123)
      %Strava{}

      iex> get_strava!(456)
      ** (Ecto.NoResultsError)

  """
  def get_strava!(id), do: Repo.get!(Strava, id)

  @doc """
  Creates a strava.

  ## Examples

      iex> create_strava(%{field: value})
      {:ok, %Strava{}}

      iex> create_strava(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_strava(user_id, attrs \\ %{}) do
    %Strava{user_id: user_id}
    |> Strava.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a strava.

  ## Examples

      iex> update_strava(strava, %{field: new_value})
      {:ok, %Strava{}}

      iex> update_strava(strava, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strava(%Strava{} = strava, attrs) do
    strava
    |> Strava.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Strava.

  ## Examples

      iex> delete_strava(strava)
      {:ok, %Strava{}}

      iex> delete_strava(strava)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strava(%Strava{} = strava) do
    Repo.delete(strava)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strava changes.

  ## Examples

      iex> change_strava(strava)
      %Ecto.Changeset{source: %Strava{}}

  """
  def change_strava(%Strava{} = strava) do
    Strava.changeset(strava, %{})
  end
end
