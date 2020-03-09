defmodule OmegaBravera.Partners do
  @moduledoc """
  The Partners context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Partners.Partner

  @doc """
  Returns the list of partner.

  ## Examples

      iex> list_partner()
      [%Partner{}, ...]

  """
  def list_partner do
    Repo.all(Partner)
  end

  @doc """
  Gets a single partner.

  Raises `Ecto.NoResultsError` if the Partner does not exist.

  ## Examples

      iex> get_partner!(123)
      %Partner{}

      iex> get_partner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_partner!(id), do: Repo.get!(Partner, id) |> Repo.preload([:location])

  @doc """
  Creates a partner.

  ## Examples

      iex> create_partner(%{field: value})
      {:ok, %Partner{}}

      iex> create_partner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_partner(attrs \\ %{}) do
    %Partner{}
    |> Partner.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a partner.

  ## Examples

      iex> update_partner(partner, %{field: new_value})
      {:ok, %Partner{}}

      iex> update_partner(partner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_partner(%Partner{} = partner, attrs) do
    partner
    |> Partner.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a partner.

  ## Examples

      iex> delete_partner(partner)
      {:ok, %Partner{}}

      iex> delete_partner(partner)
      {:error, %Ecto.Changeset{}}

  """
  def delete_partner(%Partner{} = partner) do
    Repo.delete(partner)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking partner changes.

  ## Examples

      iex> change_partner(partner)
      %Ecto.Changeset{source: %Partner{}}

  """
  def change_partner(%Partner{} = partner, attrs \\ %{}) do
    Partner.changeset(partner, attrs)
  end

  alias OmegaBravera.Partners.PartnerLocation

  @doc """
  Returns the list of partner_locations.

  ## Examples

      iex> list_partner_locations()
      [%PartnerLocation{}, ...]

  """
  def list_partner_locations do
    Repo.all(PartnerLocation)
  end

  @doc """
  Gets a single partner_location.

  Raises `Ecto.NoResultsError` if the Partner location does not exist.

  ## Examples

      iex> get_partner_location!(123)
      %PartnerLocation{}

      iex> get_partner_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_partner_location!(id), do: Repo.get!(PartnerLocation, id)

  @doc """
  Creates a partner_location.

  ## Examples

      iex> create_partner_location(%{field: value})
      {:ok, %PartnerLocation{}}

      iex> create_partner_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_partner_location(attrs \\ %{}) do
    %PartnerLocation{}
    |> PartnerLocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a partner_location.

  ## Examples

      iex> update_partner_location(partner_location, %{field: new_value})
      {:ok, %PartnerLocation{}}

      iex> update_partner_location(partner_location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_partner_location(%PartnerLocation{} = partner_location, attrs) do
    partner_location
    |> PartnerLocation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a partner_location.

  ## Examples

      iex> delete_partner_location(partner_location)
      {:ok, %PartnerLocation{}}

      iex> delete_partner_location(partner_location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_partner_location(%PartnerLocation{} = partner_location) do
    Repo.delete(partner_location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking partner_location changes.

  ## Examples

      iex> change_partner_location(partner_location)
      %Ecto.Changeset{source: %PartnerLocation{}}

  """
  def change_partner_location(%PartnerLocation{} = partner_location) do
    PartnerLocation.changeset(partner_location, %{})
  end
end
