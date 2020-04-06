defmodule OmegaBraveraWeb.AdminPartnerImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Partners
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.AdminPanelPartnerView.render("partner_images.html", assigns)

  def mount(%{"id" => partner_id}, _session, socket) do
    partner = Partners.get_partner!(partner_id)
    token = UploadAuth.generate_partner_token(partner.id)
    {:ok, assign(socket, partner: partner, images: partner.images, upload_token: token)}
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

  def handle_event("save-images", _, %{assigns: %{images: images, partner: partner}} = socket) do
    case Partners.update_partner(partner, %{images: images}) do
      {:ok, partner} ->
        {:noreply, redirect(socket, to: Routes.admin_panel_partner_path(socket, :show, partner))}
    end
  end
end