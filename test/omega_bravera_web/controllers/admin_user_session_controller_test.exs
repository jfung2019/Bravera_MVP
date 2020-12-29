defmodule OmegaBraveraWeb.AdminUserSessionControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Fixtures

  @create_attrs %{email: "some@email.com", password: "pass1234"}

  describe "new admin_user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_user_session_path(conn, :new))
      assert html_response(conn, 200) =~ "Login"
    end
  end

  describe "super admin logging in" do
    setup do
      {:ok, user: Fixtures.admin_user_fixture(@create_attrs)}
    end

    test "admin user can login", %{conn: conn} do
      conn = post(conn, admin_user_session_path(conn, :create), %{"session" => @create_attrs})
      assert redirected_to(conn) == admin_user_page_path(conn, :index)
    end

    test "bad password will send them back to login page", %{conn: conn} do
      conn =
        post(conn, admin_user_session_path(conn, :create), %{
          "session" => %{@create_attrs | password: "badpass"}
        })

      assert html_response(conn, 200) =~ "Invalid email/password combination"
    end

    test "bad email will send them back to login page", %{conn: conn} do
      conn =
        post(conn, admin_user_session_path(conn, :create), %{
          "session" => %{@create_attrs | email: "bademail"}
        })

      assert html_response(conn, 200) =~ "Invalid email/password combination"
    end
  end

  describe "partner admin logging in" do
    setup do
      {:ok, user: Fixtures.admin_user_fixture(Map.put(@create_attrs, :role, "partner"))}
    end

    test "can login and redirected to partner section", %{conn: conn} do
      conn = post(conn, admin_user_session_path(conn, :create), %{"session" => @create_attrs})
      assert redirected_to(conn) == Routes.admin_panel_partner_path(conn, :index)
    end
  end

  describe "admin user logout" do
    setup %{conn: conn} do
      user = Fixtures.admin_user_fixture(@create_attrs)
      {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

      {:ok,
       user: user, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
    end

    test "logs out an admin user", %{conn: conn} do
      conn = delete(conn, admin_user_session_path(conn, :delete))
      assert html_response(conn, 302)
    end
  end
end
