defmodule OmegaBravera.Fundraisers do
  @moduledoc """
  The Fundraisers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Fundraisers.NGO

  # Get a user's causes by user_id

  def get_ngos_by_user(user_id) do
    query = from n in NGO,
      where: n.user_id == ^user_id

    Repo.all(query)
  end

  @doc """
  Returns the list of ngos.

  ## Examples

      iex> list_ngos()
      [%NGO{}, ...]

  """
  def list_ngos do
    Repo.all(NGO)
  end

  @doc """
  Gets a single ngo.

  Raises `Ecto.NoResultsError` if the Ngo does not exist.

  ## Examples

      iex> get_ngo!(123)
      %NGO{}

      iex> get_ngo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ngo!(id), do: Repo.get!(NGO, id)


  def get_ngo_by_slug(slug) do
    query = from n in NGO,
      where: n.slug == ^slug

    Repo.one(query)
  end
  @doc """
  Creates a ngo.

  ## Examples

      iex> create_ngo(%{field: value})
      {:ok, %NGO{}}

      iex> create_ngo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ngo(attrs \\ %{}) do
    %NGO{}
    |> NGO.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ngo.

  ## Examples

      iex> update_ngo(ngo, %{field: new_value})
      {:ok, %NGO{}}

      iex> update_ngo(ngo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ngo(%NGO{} = ngo, attrs) do
    ngo
    |> NGO.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a NGO.

  ## Examples

      iex> delete_ngo(ngo)
      {:ok, %NGO{}}

      iex> delete_ngo(ngo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ngo(%NGO{} = ngo) do
    Repo.delete(ngo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ngo changes.

  ## Examples

      iex> change_ngo(ngo)
      %Ecto.Changeset{source: %NGO{}}

  """
  def change_ngo(%NGO{} = ngo) do
    NGO.changeset(ngo, %{})
  end
end
