defmodule OmegaBraveraWeb.AdminOfferImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Offers
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.AdminPanelOfferView.render("offer_images.html", assigns)

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
    {:noreply, assign(socket, images: images, to_delete: nil)}
  end

  def handle_event(
        "shift-right",
        %{"index" => string_index},
        %{assigns: %{images: images}} = socket
      ) do
    index = String.to_integer(string_index)
    new_index = index + 1
    images = swap_images(images, index, new_index)
    {:noreply, assign(socket, images: images)}
  end

  def handle_event(
        "shift-left",
        %{"index" => string_index},
        %{assigns: %{images: images}} = socket
      ) do
    index = String.to_integer(string_index)
    new_index = index - 1
    images = swap_images(images, index, new_index)
    {:noreply, assign(socket, images: images)}
  end

  def handle_event("to-delete", %{"index" => string_index}, socket),
      do: {:noreply, assign(socket, to_delete: String.to_integer(string_index))}

  def handle_event("undo-delete", _, socket), do: {:noreply, assign(socket, to_delete: nil)}

  def handle_event("save-images", _, %{assigns: %{images: images, offer: offer}} = socket) do
    case Offers.update_offer(offer, %{images: images}) do
      {:ok, updated_offer} ->
        init_image_added = length(offer.images) < length(updated_offer.images)
        socket = assign(socket, :init_image_added, init_image_added)

        {:noreply,
         redirect(socket, to: Routes.admin_panel_offer_path(socket, :show, updated_offer))}
    end
  end

  defp swap_images(images, _original_index, new_index) when length(images) == new_index,
    do: images

  defp swap_images(images, 0, new_index) when new_index < 0, do: images

  defp swap_images(images, original_index, new_index) do
    original_image = Enum.at(images, original_index)
    other_image = Enum.at(images, new_index)

    images
    |> List.replace_at(new_index, original_image)
    |> List.replace_at(original_index, other_image)
  end
end
