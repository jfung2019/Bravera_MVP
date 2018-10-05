defmodule OmegaBraveraWeb.AdminPanelNGOView do
  use OmegaBraveraWeb, :view

  def currencies() do
    OmegaBravera.Fundraisers.all_currencies()
  end
end
