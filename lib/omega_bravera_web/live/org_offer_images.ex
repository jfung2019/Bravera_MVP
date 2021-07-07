defmodule OmegaBraveraWeb.OrgOfferImages do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.{Offers, ImageHelper, Accounts}
  alias OmegaBraveraWeb.Api.UploadAuth

  def render(assigns),
    do: OmegaBraveraWeb.OrgPanelOnlineOffersView.render("offer_images.html", assigns)

  def mount(%{"slug" => slug}, %{"organization_id" => org_id}, socket) do
    offer = Offers.get_offer_by_slug(slug)
    token = UploadAuth.generate_offer_token(offer.id)
    first_10_offer_image = Offers.check_first_10_offer_image(org_id)
    organization = Accounts.get_organization!(org_id)

    {:ok,
     assign(socket,
       offer: offer,
       images: offer.images,
       upload_token: token,
       first_10_offer_image: first_10_offer_image,
       organization: organization
     )}
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

  def handle_event(
        "save-images",
        _,
        %{assigns: %{images: images, offer: offer, organization: %{account_type: :merchant}}} =
          socket
      ) do
    case Offers.update_offer(offer, %{images: images}) do
      {:ok, updated_offer} ->
        redirect_to_offer_path(socket, updated_offer)
    end
  end

  def handle_event("save-images", _, %{assigns: %{images: images, offer: offer}} = socket) do
    case Offers.update_offer(offer, %{images: images}) do
      {:ok, updated_offer} ->
        case updated_offer.offer_type do
          :online ->
            {:noreply, redirect(socket, to: Routes.org_panel_partner_path(socket, :index))}

          _ ->
            {:noreply, redirect(socket, to: Routes.org_panel_offer_reward_path(socket, :new))}
        end
    end
  end

  def redirect_to_offer_path(socket, %{approval_status: :pending, offer_type: :online, slug: slug}),
      do:
        {:noreply,
         redirect(socket,
           to: Routes.org_panel_online_offers_path(socket, :index, review_offer_slug: slug)
         )}

  def redirect_to_offer_path(socket, %{approval_status: :pending, offer_type: :in_store, slug: slug}),
      do:
        {:noreply,
         redirect(socket,
           to: Routes.org_panel_offline_offers_path(socket, :index, review_offer_slug: slug)
         )}

  def redirect_to_offer_path(socket, %{offer_type: :online}),
    do: {:noreply, redirect(socket, to: Routes.org_panel_online_offers_path(socket, :index))}

  def redirect_to_offer_path(socket, %{offer_type: :in_store}),
    do: {:noreply, redirect(socket, to: Routes.org_panel_offline_offers_path(socket, :index))}
end
