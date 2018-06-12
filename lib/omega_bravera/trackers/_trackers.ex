defmodule OmegaBravera.Trackers do
  @moduledoc """
  The Trackers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Trackers.Strava

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
  def create_strava(attrs \\ %{}) do
    %Strava{}
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
