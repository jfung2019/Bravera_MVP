defmodule OmegaBraveraWeb.Kaffy.OfferAdmin do
  import Ecto.Query

  def singular_name(_schema), do: "Activity"

  def plural_name(_schema), do: "Activities"

  def custom_index_query(_conn, _schema, query) do
    query
  end
end
