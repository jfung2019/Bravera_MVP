defmodule OmegaBraveraWeb.OrgPartnerImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Groups
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.OrgPanelPartnerView.render("partner_images.html", assigns)

  def mount(%{"id" => partner_id}, _session, socket) do
    partner = Groups.get_partner!(partner_id)
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
    case Groups.update_partner(partner, %{images: images}) do
      {:ok, updated_partner} ->
        {:noreply,
         redirect(socket, to: Routes.org_panel_partner_path(socket, :show, updated_partner))}
    end
  end
end
