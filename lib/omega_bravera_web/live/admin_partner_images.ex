defmodule OmegaBraveraWeb.AdminPartnerImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.{Groups, ImageHelper}
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.AdminPanelPartnerView.render("partner_images.html", assigns)

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
    {:noreply, assign(socket, images: images, to_delete: nil)}
  end

  def handle_event(
        "shift-right",
        %{"index" => string_index},
        %{assigns: %{images: images}} = socket
      ) do
    index = String.to_integer(string_index)
    new_index = index + 1
    images = ImageHelper.swap_images(images, index, new_index)
    {:noreply, assign(socket, images: images)}
  end

  def handle_event(
        "shift-left",
        %{"index" => string_index},
        %{assigns: %{images: images}} = socket
      ) do
    index = String.to_integer(string_index)
    new_index = index - 1
    images = ImageHelper.swap_images(images, index, new_index)
    {:noreply, assign(socket, images: images)}
  end

  def handle_event("to-delete", %{"index" => string_index}, socket),
    do: {:noreply, assign(socket, to_delete: String.to_integer(string_index))}

  def handle_event("undo-delete", _, socket), do: {:noreply, assign(socket, to_delete: nil)}

  def handle_event("save-images", _, %{assigns: %{images: images, partner: partner}} = socket) do
    case Groups.update_partner(partner, %{images: images}) do
      {:ok, partner} ->
        {:noreply, redirect(socket, to: Routes.admin_panel_partner_path(socket, :show, partner))}
    end
  end
end
