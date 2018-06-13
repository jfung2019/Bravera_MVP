defmodule OmegaBravera.Challenges do
  @moduledoc """
  The Challenges context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.NGOChal

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
  Creates a ngo_chal.

  ## Examples

      iex> create_ngo_chal(%{field: value})
      {:ok, %NGOChal{}}

      iex> create_ngo_chal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ngo_chal(attrs \\ %{}) do
    %NGOChal{}
    |> NGOChal.changeset(attrs)
    |> Repo.insert()
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
end
