defmodule OmegaBraveraWeb.AdminOfferImagesTest do
  use OmegaBraveraWeb.LiveViewCase, async: true
  @view OmegaBraveraWeb.AdminOfferImages
  import OmegaBravera.Factory

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           OmegaBravera.Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token), offer: insert(:offer, %{images: ["url1"]})}
  end

  test "can see offer name and existing photos to verify offer", %{conn: conn, offer: offer} do
    {:ok, _view, html} = live(conn, Routes.live_path(conn, @view, offer))
    assert html =~ offer.name
    Enum.each(offer.images, fn image_url -> assert html =~ image_url end)
  end
end