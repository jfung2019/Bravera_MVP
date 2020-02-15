defmodule OmegaBraveraWeb.AdminOfferImages do
  use Phoenix.LiveView
  alias OmegaBravera.Offers

  def render(assigns),
    do: OmegaBraveraWeb.AdminPanelOfferView.render("offer_images.html", assigns)

  def mount(%{"slug" => slug}, _session, socket) do
    offer = Offers.get_offer_by_slug(slug)
    {:ok, assign(socket, offer: offer, images: offer.images)}
  end
end
