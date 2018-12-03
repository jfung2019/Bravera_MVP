defmodule OmegaBraveraWeb.UserSessionControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @password "strong passowrd"

  def credential_fixture() do
    user = insert(:user)

    credential_attrs = %{
      password: @password,
      password_confirmation: @password,
      user_id: user.id
    }

    {:ok, credential} =
      Credential.changeset(%Credential{}, credential_attrs)
      |> Repo.insert()

    credential |> Repo.preload(:user)
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, page_path(conn, :login))
      assert html_response(conn, 200) =~ "Log in"
    end
  end

  describe "user logging in" do
    test "user can login", %{conn: conn} do
      credential = credential_fixture()
      attrs = %{
        email: credential.user.email,
        password: @password
      }
      conn = post(conn, user_session_path(conn, :create), %{"session" => attrs})

      assert redirected_to(conn) == user_profile_path(conn, :show)
    end

    test "bad password will send them back to login page", %{conn: conn} do
      credential = credential_fixture()
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

    test "bad email will send them back to login page", %{conn: conn} do
      credential = credential_fixture()
      attrs = %{
        email: credential.user.email,
        password: @password
      }
      conn =
        post(conn, user_session_path(conn, :create), %{
          "session" => %{attrs | email: "bademail"}
        })

      assert redirected_to(conn, 302) == page_path(conn, :login)
    end
  end

  describe "user logout" do
    setup %{conn: conn} do
      user = insert(:user)
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
