defmodule OmegaBraveraWeb.AdminPartnerImagesTest do
  use OmegaBraveraWeb.LiveViewCase, async: true
  @view OmegaBraveraWeb.AdminPartnerImages
  alias OmegaBravera.{Fixtures, Groups}

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           OmegaBravera.Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
            partner: Fixtures.partner_fixture(%{images: ["url1"]})}
  end

  test "can see partner name and existing photos to verify partner", %{
    conn: conn,
    partner: partner
  } do
    {:ok, _view, html} = live(conn, Routes.live_path(conn, @view, partner))
    assert html =~ partner.name
    Enum.each(partner.images, fn image_url -> assert html =~ image_url end)
  end

  test "can append and save new image url", %{conn: conn, partner: %{id: partner_id} = partner} do
    {:ok, view, _html} = live(conn, Routes.live_path(conn, @view, partner))
    assert render_hook(view, "append-image", %{"images" => "url2"}) =~ "url2"
    render_click(view, "save-images")
    redirected_url = Routes.admin_panel_partner_path(conn, :show, partner)
    assert_redirect(view, redirected_url)
    assert %{images: ["url1", "url2"]} = Groups.get_partner!(partner_id)
  end

  test "can remove url from images list and save", %{
    conn: conn,
    partner: %{id: partner_id} = partner
  } do
    {:ok, view, _html} = live(conn, Routes.live_path(conn, @view, partner))
    assert render_hook(view, "append-image", %{"images" => "url2"}) =~ "url2"
    html = render_click(view, "remove-image", %{"index" => "0"})
    refute html =~ "url1"
    assert html =~ "url2"
    render_click(view, "save-images")
    redirected_url = Routes.admin_panel_partner_path(conn, :show, partner)
    assert_redirect(view, redirected_url)
    assert %{images: ["url2"]} = Groups.get_partner!(partner_id)
  end
end
