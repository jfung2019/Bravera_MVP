defmodule OmegaBraveraWeb.LiveUserSignupTest do
  use OmegaBraveraWeb.LiveViewCase

  alias OmegaBravera.{Accounts, Repo}

  @view OmegaBraveraWeb.LiveUserSignup

  setup do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa",
      email: "sheriefalaa.w@gmail.com",
      email_verified: true,
      accept_terms: true,
      location_id: 1,
      credential: %{"password" => "testing", "password_confirmation" => "testing"}
    }

    with {:ok, user} <- Accounts.create_credential_user(attrs), do: {:ok, user: user}
  end

  describe "live signup" do
    test "LiveUserSignup can handle event validate can validate user input" do
      {:ok, view, _html} = mount(@endpoint, @view, session: %{redirect_uri: "/", add_team_member_redirect_uri: nil})

      params = %{
        "firstname" => "allen",
        "lastname" => "bond",
        "email" => "allen_bond@plangora.com",
        "accept_terms" => true,
        "location_id" => "1",
        "credential" => %{
          "password" => "leet_bond!",
          "password_confirmation" => "leet_bond!"
        }
      }

      html = render_change(view, "validate", %{"user" => params})

      refute html =~ "is-invalid"
    end

    test "LiveUserSignup can handle event signup can create credential user" do
      {:ok, view, _html} = mount(@endpoint, @view, session: %{redirect_uri: "/", add_team_member_redirect_uri: nil})

      params = %{
        "firstname" => "allen",
        "lastname" => "bond",
        "email" => "allen_bond@plangora.com",
        "location_id" => 1,
        "accept_terms" => true,
        "credential" => %{
          "password" => "leet_bond!",
          "password_confirmation" => "leet_bond!"
        }
      }

      html = render_change(view, "validate", %{"user" => params})

      refute html =~ "is-invalid"

      render_click(view, "signup", %{"user" => params})

      assert %Accounts.User{} = Repo.get_by(Accounts.User, email: "allen_bond@plangora.com")
    end

    test "LiveUserSignup can handle event signup refuses user if exists" do
      {:ok, view, _html} = mount(@endpoint, @view, session: %{redirect_uri: "/", add_team_member_redirect_uri: nil})

      params = %{
        firstname: "sherief",
        lastname: "alaa",
        email: "sheriefalaa.w@gmail.com",
        accept_terms: "true",
        location_id: 1,
        credential: %{"password" => "testing", "password_confirmation" => "testing"}
      }

      render_change(view, "signup", %{"user" => params})
      html = render_click(view, "signup", %{"user" => params})

      assert html =~ "has already been taken"
    end
  end
end
