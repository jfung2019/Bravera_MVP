defmodule OmegaBraveraWeb.UserSessionControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @password "Dev@1234"

  def credential_fixture() do
    user = insert(:user)

    credential_attrs = %{
      password: @password,
      password_confirmation: @password
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
      |> Repo.insert()

    credential |> Repo.preload(:user)
  end

  describe "new user" do
    @tag :skip
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.page_path(conn, :login))
      assert html_response(conn, 200) =~ "Log in"
    end
  end

  describe "user logging in" do
    setup do: {:ok, credential: credential_fixture()}

    test "user can login", %{conn: conn, credential: credential} do
      attrs = %{
        email: credential.user.email,
        password: @password
      }

      conn = post(conn, Routes.user_session_path(conn, :create), %{"session" => attrs})

      assert redirected_to(conn) == Routes.user_profile_path(conn, :show)
    end

    test "user with a session to after_login_redirect will be redirected", %{
      conn: conn,
      credential: credential
    } do
      root_path = Routes.page_path(conn, :index)

      attrs = %{
        email: credential.user.email,
        password: @password
      }

      conn =
        conn
        |> bypass_through(OmegaBraveraWeb.Router, :browser)
        |> get("/")
        |> put_session("after_login_redirect", root_path)
        |> send_resp(:ok, "")
        |> post(Routes.user_session_path(conn, :create), %{"session" => attrs})

      assert ^root_path = redirected_to(conn)
    end

    @tag :skip
    test "bad password will send them back to login page", %{conn: conn, credential: credential} do
      attrs = %{
        email: credential.user.email,
        password: @password
      }

      conn =
        post(conn, user_session_path(conn, :create), %{
          "session" => %{attrs | password: "badpass"}
        })

      assert redirected_to(conn, 302) == page_path(conn, :login)
    end

    @tag :skip
    test "bad email will send them back to login page", %{conn: conn, credential: credential} do
      attrs = %{
        email: credential.user.email,
        password: @password
      }

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "session" => %{attrs | email: "bademail"}
        })

      assert redirected_to(conn, 302) == Routes.page_path(conn, :login)
    end
  end

  describe "user logout" do
    setup %{conn: conn} do
      user = insert(:user)
      {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

      {:ok,
       user: user, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
    end

    @tag :skip
    test "logs out an user", %{conn: conn} do
      conn =
        conn
        |> get(Routes.strava_path(conn, :logout))

      assert html_response(conn, 302)
    end
  end
end
