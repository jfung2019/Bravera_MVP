defmodule OmegaBravera.Accounts.NotifierTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory
  alias OmegaBravera.Accounts.{Notifier, User}

  test "user_signup_email/1 builds the signup email for the sendgrid template" do
    user = insert(:user, %{firstname: "Rafael", lastname: "Garcia", email: "simon.garciar@gmail.com"})
    result = Notifier.user_signup_email(user)

    assert result == %SendGrid.Email{
      __phoenix_layout__: nil,
      __phoenix_view__: nil,
      attachments: nil,
      bcc: nil,
      cc: nil,
      content: nil,
      custom_args: nil,
      from: %{email: "admin@bravera.co", name: "Bravera"},
      headers: nil,
      reply_to: nil,
      send_at: nil,
      subject: nil,
      substitutions: %{"-fullName-" => "Rafael Garcia"},
      template_id: "b47d2224-792a-43d8-b4b2-f53b033d2f41",
      to: [%{email: "simon.garciar@gmail.com"}]
    }
  end

  test "send_user_signup_email/1 sends the user signup email" do
    user = insert(:user)
    result = Notifier.send_user_signup_email(user)

    assert result == :ok
  end

  test "signups_digest_email/1 builds the daily signups digest email" do
    params = %{
      users_count: 1,
      csv: "firstname,lastname,email,strava_id,sex,location\r\nRafael,Garcia,camonz@camonz.com,33762738 (https://www.strava.com/athletes/33762738),M,Not specified\r\n"
    }

    result = Notifier.signups_digest_email(params)

    assert result == %SendGrid.Email{
      __phoenix_layout__: nil,
      __phoenix_view__: nil,
      attachments: nil,
      bcc: nil,
      cc: nil,
      content: nil,
      custom_args: nil,
      from: %{email: "admin@bravera.co", name: "Bravera"},
      headers: nil,
      reply_to: nil,
      send_at: nil,
      substitutions: nil,
      template_id: nil,
      to: [%{email: "admin@bravera.co"}],
      attachments: [
        %{
          content: "Zmlyc3RuYW1lLGxhc3RuYW1lLGVtYWlsLHN0cmF2YV9pZCxzZXgsbG9jYXRpb24NClJhZmFlbCxHYXJjaWEsY2Ftb256QGNhbW9uei5jb20sMzM3NjI3MzggKGh0dHBzOi8vd3d3LnN0cmF2YS5jb20vYXRobGV0ZXMvMzM3NjI3MzgpLE0sTm90IHNwZWNpZmllZA0K",
          filename: "signups_2018-09-11.csv"
        }
      ],
      content: [
        %{
          type: "text/plain",
          value: "In the past 24h we've had 1 signups, attached is a CSV with their details"
        }
      ],
      subject: "User signups digest"
    }
  end

  test "send_signups_digest/1 sends the daily signups digest email" do
    params = %{
      users_count: 1,
      csv: "firstname,lastname,email,strava_id,sex,location\r\nRafael,Garcia,camonz@camonz.com,33762738 (https://www.strava.com/athletes/33762738),M,Not specified\r\n"
    }

    result = Notifier.send_signups_digest(params)

    assert result == :ok
  end
end
