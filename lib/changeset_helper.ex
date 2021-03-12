defmodule OmegaBravera.ChangesetHelper do
  import Ecto.Changeset

  def cast_geom(changeset) do
    case changeset do
      %{valid?: true, changes: %{longitude: longitude, latitude: latitude}} ->
        put_change(changeset, :geom, %Geo.Point{
          coordinates: {Decimal.to_float(longitude), Decimal.to_float(latitude)},
          srid: 4326
        })

      _ ->
        changeset
    end
  end

  def mark_for_delete(changeset) do
    if get_change(changeset, :remove) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
