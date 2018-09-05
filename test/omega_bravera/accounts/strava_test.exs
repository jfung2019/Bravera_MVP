defmodule OmegaBravera.Accounts.StravaTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias OmegaBravera.{Accounts, Trackers}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

    attrs = %{
      athlete_id: 33762738,
      email: "simon.garciar@gmail.com",
      firstname: "Rafael",
      lastname: "Garcia",
      token: "87318aaded9cdeb99a1a3c20c6af26ccf059de30"
    }

    [attrs: attrs]
  end

  test "login_changeset/1 returns the login params returned by Strava", %{attrs: attrs} do
    params = %{"code" => "ddca33888c1a5abaf14259adaae4da42398ec2ba", "scope" => "view_private", "state" => ""}

    use_cassette "strava_signup_sign_in_flow" do
      result = Accounts.Strava.login_changeset(params)

      assert result == attrs
    end
  end

  describe "create_user_with_tracker/1" do
    test "creates both user and tracker within a transaction", %{attrs: attrs} do
      {:ok, %{strava: strava, user: user}} = Accounts.Strava.create_user_with_tracker(attrs)

      assert match?(%Accounts.User{}, user) == true
      assert user.email == "simon.garciar@gmail.com"

      assert match?(%Trackers.Strava{}, strava) == true
      assert strava.athlete_id == 33762738
    end

    test "fails if either the user is already on the db", %{attrs: attrs} do
      {:ok, _} = Accounts.create_user(Map.take(attrs, [:firstname, :lastname, :email]))

      {:error, :user, changeset, _} = Accounts.Strava.create_user_with_tracker(attrs)

      assert changeset.errors == [email: {"has already been taken", []}]
    end
  end

  test "build_email/1 builds the signup email for the sendgrid template", %{attrs: attrs} do
    {:ok, user} = Accounts.create_user(Map.take(attrs, [:firstname, :lastname, :email]))

    result = Accounts.Strava.build_email(user)

    assert result == %SendGrid.Email{
      __phoenix_layout__: nil,
      __phoenix_view__: nil,
      attachments: nil,
      bcc: nil,
      cc: nil,
      content: nil,
      custom_args: nil,
      from: %{email: "admin@bravera.co"},
      headers: nil,
      reply_to: nil,
      send_at: nil,
      subject: nil,
      substitutions: %{"-fullName-" => "Rafael Garcia"},
      template_id: "b47d2224-792a-43d8-b4b2-f53b033d2f41",
      to: [%{email: "simon.garciar@gmail.com"}]
    }
  end
end
