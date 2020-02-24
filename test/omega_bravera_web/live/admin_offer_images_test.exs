defmodule OmegaBraveraWeb.AdminOfferImagesTest do
  use OmegaBraveraWeb.LiveViewCase, async: true
  @view OmegaBraveraWeb.AdminOfferImages
  import OmegaBravera.Factory
  alias OmegaBravera.Offers

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           OmegaBravera.Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
            offer: insert(:offer, %{images: ["url1"], location_id: 1})}
  end

  test "can see offer name and existing photos to verify offer", %{conn: conn, offer: offer} do
    {:ok, _view, html} = live(conn, Routes.live_path(conn, @view, offer))
    assert html =~ offer.name
    Enum.each(offer.images, fn image_url -> assert html =~ image_url end)
  end

  test "can append and save new image url", %{conn: conn, offer: %{id: offer_id} = offer} do
    {:ok, view, _html} = live(conn, Routes.live_path(conn, @view, offer))
    assert render_hook(view, "append-image", %{"images" => "url2"}) =~ "url2"
    render_click(view, "save-images")
    redirected_url = Routes.admin_panel_offer_path(conn, :show, offer)
    assert_redirect(view, ^redirected_url)
    assert %{images: ["url1", "url2"]} = Offers.get_offer!(offer_id)
  end

  test "can remove url from images list and save", %{conn: conn, offer: %{id: offer_id} = offer} do
    {:ok, view, _html} = live(conn, Routes.live_path(conn, @view, offer))
    assert render_hook(view, "append-image", %{"images" => "url2"}) =~ "url2"
    html = render_click(view, "remove-image", %{"index" => "0"})
    refute html =~ "url1"
    assert html =~ "url2"
    render_click(view, "save-images")
    redirected_url = Routes.admin_panel_offer_path(conn, :show, offer)
    assert_redirect(view, ^redirected_url)
    assert %{images: ["url2"]} = Offers.get_offer!(offer_id)
  end
end
