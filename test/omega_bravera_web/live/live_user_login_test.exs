defmodule OmegaBraveraWeb.LiveUserLoginTest do
  use OmegaBraveraWeb.LiveViewCase

  alias OmegaBravera.Accounts

  @view OmegaBraveraWeb.LiveUserLogin

  setup do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa",
      email: "sheriefalaa.w@gmail.com",
      email_verified: true,
      credential: %{"password" => "testing", "password_confirmation" => "testing"}
    }

    with {:ok, user} <- Accounts.create_credential_user(attrs), do: {:ok, user: user}
  end

  describe "login" do
    test "LiveUserLogin can handle event validate can validate user input" do
      {:ok, view, _html} = mount(@endpoint, @view, session: %{csrf: "123"})

      params = %{"email" => "sherief", "password" => "foo"}
      html = render_change(view, "validate", %{"session" => params})

      assert html =~ "invalid format"
      assert html =~ "should be at least 6 character(s)"

      params = %{"email" => "sheriefalaa.w@gmail.com", "password" => "testing"}
      html = render_change(view, "validate", %{"session" => params})

      refute html =~ "invalid format"
      refute html =~ "should be at least 6 character(s)"
    end

    test "LiveUserLogin can handle event validate can validate if user exists" do
      {:ok, view, _html} = mount(@endpoint, @view, session: %{csrf: "123"})

      params = %{"email" => "fakesherief@example.com", "password" => "testing"}
      html = render_change(view, "validate", %{"session" => params})

      assert html =~ "Seems you don&#39;t have an account, please sign up."
    end
  end
end
