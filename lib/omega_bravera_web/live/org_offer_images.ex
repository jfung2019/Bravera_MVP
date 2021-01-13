defmodule OmegaBraveraWeb.OrgOfferImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Offers
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.OrgPanelOnlineOffersView.render("offer_images.html", assigns)

  def mount(%{"slug" => slug}, _session, socket) do
    offer = Offers.get_offer_by_slug(slug)
    token = UploadAuth.generate_offer_token(offer.id)
    {:ok, assign(socket, offer: offer, images: offer.images, upload_token: token)}
  end

  def handle_event(
        "append-image",
        %{"images" => image_url},
        %{assigns: %{images: images}} = socket
      ),
      do: {:noreply, assign(socket, images: images ++ [image_url])}

  def handle_event(
        "remove-image",
        %{"index" => string_index},
        %{assigns: %{images: images}} = socket
      ) do
    index = String.to_integer(string_index)
    images = List.delete_at(images, index)
    {:noreply, assign(socket, images: images)}
  end

  def handle_event("save-images", _, %{assigns: %{images: images, offer: offer}} = socket) do
    case Offers.update_offer(offer, %{images: images}) do
      {:ok, offer} ->
        {:noreply, redirect(socket, to: Routes.admin_panel_offer_path(socket, :show, offer))}
    end
  end
end
