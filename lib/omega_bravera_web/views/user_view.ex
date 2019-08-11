defmodule OmegaBraveraWeb.UserView do
  use OmegaBraveraWeb, :view

  def generate_locations(locations), do: Enum.map(locations, &{"#{&1.name_en}", &1.id})
end
