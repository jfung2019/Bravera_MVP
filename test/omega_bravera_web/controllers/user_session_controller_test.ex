defmodule OmegaBraveraWeb.UserSessionControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts

  @create_attrs %{email: "email@example.com", password: "pass1234"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, page_path(conn, :login))
      assert html_response(conn, 200) =~ "Log in"
    end
  end

  describe "user logging in" do
    setup do
      {:ok, user: fixture(:user)}
    end

    test "user can login", %{conn: conn} do
      conn = post(conn, user_session_path(conn, :create), %{"session" => @create_attrs})
      assert redirected_to(conn) == "/"
    end

    test "bad password will send them back to login page", %{conn: conn} do
      conn =
        post(conn, user_session_path(conn, :create), %{
          "session" => %{@create_attrs | password: "badpass"}
        })

      assert redirected_to(conn, 302) == page_path(conn, :login)
    end

    test "bad email will send them back to login page", %{conn: conn} do
      conn =
        post(conn, user_session_path(conn, :create), %{
          "session" => %{@create_attrs | email: "bademail"}
        })

      assert redirected_to(conn, 302) == page_path(conn, :login)
    end
  end

  describe "user logout" do
    setup %{conn: conn} do
      user = fixture(:user)
      {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

      {:ok,
       user: user, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
    end

    test "logs out an user", %{conn: conn} do
      conn =
        conn
        |> get(strava_path(conn, :logout))

      assert html_response(conn, 302)
    end
  end
end
