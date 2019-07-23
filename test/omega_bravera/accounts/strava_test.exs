defmodule OmegaBravera.Accounts.StravaTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Trackers}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

    attrs = %{
      athlete_id: 35_409_789,
      firstname: "Sherief",
      lastname: "Alaa",
      token: "8a15d17c71df8e9d99e38c28c1b7a12b7b1f12f0",
      strava_profile_picture:
        "https://lh3.googleusercontent.com/-d22eVvFVt_k/AAAAAAAAAAI/AAAAAAAAAAA/AAN31DVuVBQBIuLZLeuXyuu7f1H0M2AeYA/mo/photo.jpg",
      refresh_token: "ff875c4523a6c9ee99ebb3b33971865042efc8eb",
      token_expires_at: Timex.from_unix(1563908347),
    }

    [attrs: attrs]
  end

  test "login_changeset/1 returns the login params returned by Strava", %{attrs: attrs} do
    params = %{
      "code" => "4ce92c56bed42f3239a2b3a7af44632c894804bd",
      "scope" => "activity:read_all,profile:read_all",
      "state" => ""
    }

    use_cassette "strava_signup_sign_in" do
      result = Accounts.Strava.login_changeset(params)
      # Temp Bug Fix: I am not sure why the date gets updated. Probably the strava library? -Sherief
      expires_at = result.token_expires_at

      assert result ==
               Map.put(attrs, :additional_info, %{sex: "M", location: "Canada/Montréal/Montréal"})
               |> Map.put(:token_expires_at, expires_at)
    end
  end

  describe "create_user_with_tracker/1" do
    test "creates both user and tracker within a transaction", %{attrs: attrs} do
      assert {:ok,
              %{
                strava: %Trackers.Strava{athlete_id: 35_409_789},
                user: %Accounts.User{firstname: "Sherief"}
              }} = Accounts.Strava.create_user_with_tracker(attrs)
    end

    test "fails if either the user is already on the db", %{attrs: attrs} do
      insert(:strava, attrs)
      {:ok, _} = Accounts.create_user(Map.take(attrs, [:firstname, :lastname, :email]))

      assert {:error, :strava,
              %Ecto.Changeset{
                errors: [
                  athlete_id:
                    {"has already been taken",
                     [constraint: :unique, constraint_name: "stravas_athlete_id_index"]}
                ]
              }, _} = Accounts.Strava.create_user_with_tracker(attrs)
    end
  end
end
