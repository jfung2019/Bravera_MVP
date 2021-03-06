defmodule OmegaBravera.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Locations.Location

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations()
      [%Location{}, ...]

  """
  def list_locations_query() do
    from(l in Location, order_by: [asc: l.name_en])
  end

  def list_locations do
    list_locations_query()
    |> Repo.all()
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Location.

  ## Examples

      iex> delete_location(location)
      {:ok, %Location{}}

      iex> delete_location(location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{source: %Location{}}

  """
  def change_location(%Location{} = location) do
    Location.changeset(location, %{})
  end

  @doc """
  Used to load all countries into DB without Hong Kong
  """
  def import do
    Countries.all()
    |> Enum.reject(fn c -> String.contains?(c.name, "Hong Kong") end)
    |> Enum.each(fn c ->
      attrs =
        case c.geo do
          %{latitude: latitude, longitude: longitude}
          when is_number(latitude) and is_number(longitude) ->
            %{name_en: c.name, name_zh: "N/A", latitude: latitude, longitude: longitude}

          _ ->
            %{name_en: c.name, name_zh: "N/A"}
        end

      create_location(attrs)
    end)
  end
end
