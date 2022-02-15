defmodule OmegaBravera.Trackers do
  @moduledoc """
  The Trackers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Challenges.NGOChal

  def create_or_update_tracker(
        %{id: user_id},
        %{
          token: token,
          strava_profile_picture: strava_profile_picture,
          refresh_token: refresh_token
        } = changeset
      ) do
    case Repo.get_by(Strava, user_id: user_id) do
      nil ->
        create_strava(user_id, changeset)

      strava ->
        # is this some convoluted way of saying to update it when the token's been refreshed?
        unless strava.token == token and strava.refresh_token == refresh_token and
                 strava.strava_profile_picture == strava_profile_picture do
          update_strava(strava, changeset)
        end
    end
  end

  def get_strava_ngo_chals(athlete_id) do
    query =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: nc in NGOChal,
        where: s.user_id == nc.user_id and nc.status == "active",
        select: {
          nc.id,
          s.token
        }
      )

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

  def list_stravas_with_no_refresh_tokens() do
    from(s in Strava, where: is_nil(s.refresh_token) == true) |> Repo.all()
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

  def get_strava_with_athlete_id(athlete_id, preloads \\ [:user]) do
    from(
      s in Strava,
      where: s.athlete_id == ^athlete_id,
      preload: ^preloads
    )
    |> Repo.one()
  end

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
  Removes the Strava connection and resets the user to use device sync type.
  """
  @spec delete_strava_reset_user_sync_type(Strava.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def delete_strava_reset_user_sync_type(%Strava{user_id: user_id} = strava) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:strava, strava)
    |> Ecto.Multi.run(:switch_sync_type, fn _repo, _ ->
      OmegaBravera.Accounts.switch_sync_type(user_id, :device)
    end)
    |> Repo.transaction()
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
