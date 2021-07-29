defmodule OmegaBraveraWeb.Admin.PartnerControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "Test@1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "partner created" do
    setup do: {:ok, partner: Fixtures.partner_fixture()}

    test "can list all of the partners", %{partner: partner, conn: conn} do
      conn = get(conn, Routes.admin_panel_partner_path(conn, :index))
      assert html_response(conn, 200) =~ partner.name
    end

    test "can edit the partner", %{partner: partner, conn: conn} do
      conn = get(conn, Routes.admin_panel_partner_path(conn, :edit, partner))
      assert html_response(conn, 200) =~ "Edit Group"
    end

    test "can re-render form if bad editing", %{partner: partner, conn: conn} do
      conn =
        put(conn, Routes.admin_panel_partner_path(conn, :update, partner), %{
          partner: %{name: nil}
        })

      assert get_flash(conn, :error) =~ "Partner was not updated"
      assert html_response(conn, 200)
    end

    test "can show the partner", %{conn: conn, partner: partner} do
      conn = get(conn, Routes.admin_panel_partner_path(conn, :show, partner))
      assert html_response(conn, 200)
    end
  end

  test "can render new partner form", %{conn: conn} do
    conn = get(conn, Routes.admin_panel_partner_path(conn, :new))
    assert html_response(conn, 200) =~ "New Group"
  end

  test "can create new partner", %{conn: conn} do
    conn =
      post(conn, Routes.admin_panel_partner_path(conn, :create), %{
        partner: %{name: "Test", introduction: "Some intro", short_description: "Test"}
      })

    assert %{id: partner_id} = redirected_params(conn)
    assert redirected_to(conn) == Routes.admin_panel_partner_path(conn, :show, partner_id)
    assert get_flash(conn, :info) =~ "Partner created successfully"
  end

  test "bad create will re-render form", %{conn: conn} do
    conn = post(conn, Routes.admin_panel_partner_path(conn, :create), %{partner: %{name: nil}})
    assert get_flash(conn, :error) =~ "Partner wasn't created"
    assert html_response(conn, 200)
  end
end
