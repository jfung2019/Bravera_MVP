defmodule OmegaBraveraWeb.OrgPanelOfferRewardView do
  use OmegaBraveraWeb, :view

  def generate_offers_list(offers) do
    Enum.map(offers, &{"#{&1.name}", &1.id})
  end
end
