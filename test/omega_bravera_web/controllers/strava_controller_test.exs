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
    token: "some token"
  }
  @user_create_attrs %{
    email: "sherief@plangora.com",
    firstname: "firstname",
    lastname: "lastname"
  }

  def fixture(:strava) do
    {:ok, strava} = Trackers.create_strava(1, @create_attrs)
    strava
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)
    user
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
        "scope" => "view_private",
        "redirect_to" => "/",
        "state" => ""
      }

      changeset = %{
        additional_info: %{location: "Canada/Montréal/Montréal", sex: nil},
        athlete_id: 42,
        email: "sherief@plangora.com",
        firstname: "Sherief",
        lastname: "Alaa",
        token: "e5a4712333abdc9a6e24911e5e491231239cf"
      }

      with_mock(Strava, [], login_changeset: fn _code -> changeset end) do
        conn = get(conn, strava_path(conn, :strava_callback, params))
        assert redirected_to(conn) == "/"
        assert called(Strava.login_changeset(params))
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
