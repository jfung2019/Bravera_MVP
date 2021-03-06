defmodule OmegaBraveraWeb.Admin.UserControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Repo, Trackers}

  @user_create_attrs %{
    email: "test@test.com",
    firstname: "some firstname",
    lastname: "some lastname",
    location_id: 1,
    setting: %{
      date_of_birth: DateTime.truncate(Timex.now(), :second),
      gender: "Male"
    }
  }

  @tracker_create_attrs %{
    email: "test@test.com",
    firstname: "some firstname",
    lastname: "some lastname",
    athlete_id: 123_456,
    token: "132kans81h23",
    refresh_token: "abcd129031092asd}",
    token_expires_at: Timex.shift(Timex.now(), hours: 5)
  }

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "Test@1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)
    {:ok, _strava} = Trackers.create_strava(user.id, @tracker_create_attrs)
    user |> Repo.preload(:strava)
  end

  describe "index" do
    setup [:create_user]

    test "lists all users in admin panel", %{conn: conn} do
      conn = get(conn, admin_panel_user_path(conn, :index))
      assert html_response(conn, 200) =~ "Users"
    end

    test "shows a specific user", %{conn: conn, user: user} do
      conn = get(conn, admin_panel_user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "#{user.firstname} #{user.lastname}"
    end

    test "gdpr delete user", %{conn: conn, user: user} do
      conn = delete(conn, admin_panel_user_path(conn, :delete, user))
      assert redirected_to(conn) == admin_panel_user_path(conn, :index)
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
