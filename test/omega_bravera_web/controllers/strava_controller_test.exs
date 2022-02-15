defmodule OmegaBraveraWeb.StravaControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  import Mock

  alias OmegaBravera.Trackers
  alias OmegaBravera.Accounts.Strava
  alias OmegaBravera.Accounts

  @create_attrs %{
    athlete_id: 42,
    email: "sherief@plangora.com",
    firstname: "Sherief",
    lastname: "Alaa",
    token: "some token",
    refresh_token: "abcd129031092asd}",
    token_expires_at: Timex.shift(Timex.now(), hours: 5)
  }
  @user_create_attrs %{
    email: "sherief@plangora.com",
    firstname: "firstname",
    lastname: "lastname",
    location_id: 1
  }

  describe "strava webhook" do
    setup [:create_user, :create_strava]

    test "returns a proper response when doing the hub challenge", %{conn: conn} do
      secret = "super_secret"

      conn =
        conn
        |> get(Routes.strava_path(conn, :get_webhook_callback), %{"hub.challenge" => secret})

      assert json_response(conn, 200) == %{
               "hub.mode" => "subscribe",
               "hub.challenge" => secret,
               "hub.verify_token" => "STRAVA"
             }
    end

    test "removes strava record and sets user to device sync after receiving webhook of not authorized",
         %{conn: conn, strava: %{athlete_id: athlete_id, user_id: user_id}} do
      Accounts.switch_sync_type(user_id, :strava)
      conn =
        conn
        |> post(Routes.strava_path(conn, :post_webhook_callback), %{
          "aspect_type" => "update",
          "event_time" => 1,
          "object_id" => athlete_id,
          "object_type" => "athlete",
          "owner_id" => athlete_id,
          "subscription_id" => 1,
          "updates" => %{"authorized" => "false"}
        })

      assert %{"status" => 200} = json_response(conn, 200)
      assert is_nil(Trackers.get_strava_with_athlete_id(athlete_id))
      assert %{sync_type: :device} = Accounts.get_user!(user_id)
    end
  end

  test "strava redirect will use session path for after login redirect", %{conn: conn} do
    root_path = Routes.page_path(conn, :index)

    conn =
      conn
      |> bypass_through(OmegaBraveraWeb.Router, :browser)
      |> get("/")
      |> put_session("after_login_redirect", root_path)
      |> send_resp(:ok, "")
      |> get(strava_path(conn, :authenticate))

    assert "https://www.strava.com/oauth/authorize?client_id=23267&redirect_uri=http%3A%2F%2Flocalhost%3A4001%2Fstrava%2Fcallback%3Fredirect_to%3D%252F&response_type=code&scope=activity%3Aread_all%2Cprofile%3Aread_all" =
             redirected_to(conn)
  end

  describe "strava login" do
    setup [:create_user]

    test "when the correct login params are provided, login user and redirect", %{
      conn: conn,
      user: user
    } do
      {:ok, _strava} = Trackers.create_strava(user.id, @create_attrs)

      params = %{
        "code" => "some code",
        "scope" => "activity:read_all,profile:read_all",
        "redirect_to" => "/",
        "state" => ""
      }

      changeset = %{
        additional_info: %{location: "Canada/Montréal/Montréal", sex: nil},
        athlete_id: 42,
        email: "sherief@plangora.com",
        firstname: "Sherief",
        lastname: "Alaa",
        token: "e5a4712333abdc9a6e24911e5e491231239cf",
        strava_profile_picture: "some-profile-picture.png",
        refresh_token: "abcd129031092asd}",
        token_expires_at: Timex.shift(Timex.now(), hours: 5)
      }

      with_mock(Strava, [], login_changeset: fn _code -> changeset end) do
        conn = get(conn, strava_path(conn, :strava_callback, params))
        assert redirected_to(conn) == "/"
        assert called(Strava.login_changeset(params))
      end
    end
  end

  defp create_user(_) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)
    {:ok, user: user}
  end

  defp create_strava(%{user: %{id: user_id}}) do
    {:ok, strava} = Trackers.create_strava(user_id, @create_attrs)
    {:ok, strava: strava}
  end
end
