defmodule OmegaBravera.Accounts.StravaTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Trackers}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

    attrs = %{
      athlete_id: 33_762_738,
      firstname: "Rafael",
      lastname: "Garcia",
      token: "8089de39cdfb41470291b9a116f1fc6b94633ad0",
      strava_profile_picture: "https://graph.facebook.com/10160635840075043/picture?height=256&width=256"
    }

    [attrs: attrs]
  end

  test "login_changeset/1 returns the login params returned by Strava", %{attrs: attrs} do
    params = %{
      "code" => "ddca33888c1a5abaf14259adaae4da42398ec2ba",
      "scope" => "view_private",
      "state" => ""
    }

    use_cassette "strava_signup_sign_in_flow" do
      result = Accounts.Strava.login_changeset(params)

      assert result ==
               Map.put(attrs, :additional_info, %{sex: "M", location: "Spain/Barcelona/Barcelona"})
    end
  end

  describe "create_user_with_tracker/1" do
    test "creates both user and tracker within a transaction", %{attrs: attrs} do
      {:ok, %{strava: strava, user: user}} = Accounts.Strava.create_user_with_tracker(attrs)

      assert match?(%Accounts.User{}, user) == true
      assert user.firstname == "Rafael"

      assert match?(%Trackers.Strava{}, strava) == true
      assert strava.athlete_id == 33_762_738
    end

    test "fails if either the user is already on the db", %{attrs: attrs} do
      insert(:strava, attrs)
      {:ok, _} = Accounts.create_user(Map.take(attrs, [:firstname, :lastname, :email]))

      {:error, :strava, changeset, _} = Accounts.Strava.create_user_with_tracker(attrs)

      assert changeset.errors == [
               athlete_id:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "stravas_athlete_id_index"]}
             ]
    end
  end
end
