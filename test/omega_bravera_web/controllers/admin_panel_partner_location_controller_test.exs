defmodule OmegaBraveraWeb.AdminPanelPartnerLocationControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
            partner: Fixtures.partner_fixture()}
  end

  test "can create partner location", %{conn: conn, partner: partner} do
    conn =
      post(
        conn,
        Routes.admin_panel_partner_admin_panel_partner_location_path(conn, :create, partner),
        %{partner_location: %{address: "123", longitude: "123.4", latitude: "456.7"}}
      )

    assert get_flash(conn, :info) == "Partner location created"
    assert redirected_to(conn) == Routes.admin_panel_partner_path(conn, :show, partner.id)
  end

  describe "partner location created" do
    setup %{partner: partner} do
      {:ok, location: Fixtures.partner_location_fixture(%{partner_id: partner.id})}
    end

    test "can edit partner location form", %{conn: conn, partner: partner, location: location} do
      conn =
        get(
          conn,
          Routes.admin_panel_partner_admin_panel_partner_location_path(
            conn,
            :edit,
            partner,
            location
          )
        )

      assert html_response(conn, 200)
    end

    test "can edit partner location", %{conn: conn, partner: partner, location: location} do
      conn =
        put(
          conn,
          Routes.admin_panel_partner_admin_panel_partner_location_path(
            conn,
            :update,
            partner,
            location
          ),
          %{partner_location: %{address: "456", longitude: "123.5", latitude: "456.8"}}
        )

      assert get_flash(conn, :info) == "Partner location updated"
      assert redirected_to(conn) == Routes.admin_panel_partner_path(conn, :show, partner.id)
    end

    test "can delete partner location", %{conn: conn, partner: partner, location: location} do
      conn =
        delete(
          conn,
          Routes.admin_panel_partner_admin_panel_partner_location_path(
            conn,
            :delete,
            partner,
            location
          ),
          %{partner_location: %{address: "456", longitude: "123.5", latitude: "456.8"}}
        )

      assert get_flash(conn, :info) == "Partner location deleted"
      assert redirected_to(conn) == Routes.admin_panel_partner_path(conn, :show, partner.id)
    end
  end
end
