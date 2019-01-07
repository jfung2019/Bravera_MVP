defmodule OmegaBravera.Accounts.StravaTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias OmegaBravera.{Accounts, Trackers}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

    attrs = %{
      athlete_id: 33_762_738,
      email: "simon.garciar@gmail.com",
      firstname: "Rafael",
      lastname: "Garcia",
      token: "87318aaded9cdeb99a1a3c20c6af26ccf059de30",
      profile_picture: "https://graph.facebook.com/10160635840075043/picture?height=256&width=256"
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

      assert result == Map.put(attrs, :additional_info, %{sex: "M", location: "//"})
    end
  end

  describe "create_user_with_tracker/1" do
    test "creates both user and tracker within a transaction", %{attrs: attrs} do
      {:ok, %{strava: strava, user: user}} = Accounts.Strava.create_user_with_tracker(attrs)

      assert match?(%Accounts.User{}, user) == true
      assert user.email == "simon.garciar@gmail.com"

      assert match?(%Trackers.Strava{}, strava) == true
      assert strava.athlete_id == 33_762_738
    end

    test "fails if either the user is already on the db", %{attrs: attrs} do
      {:ok, _} = Accounts.create_user(Map.take(attrs, [:firstname, :lastname, :email]))

      {:error, :user, changeset, _} = Accounts.Strava.create_user_with_tracker(attrs)

      assert changeset.errors == [email: {"has already been taken", []}]
    end
  end
end
