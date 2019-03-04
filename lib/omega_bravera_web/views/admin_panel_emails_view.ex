defmodule OmegaBraveraWeb.AdminPanelEmailsView do
  use OmegaBraveraWeb, :view

  def generate_categories_list(categories) do
    Enum.map(categories, &{"#{&1.title}", &1.id})
  end
end
