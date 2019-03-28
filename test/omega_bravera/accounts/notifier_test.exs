defmodule OmegaBravera.Accounts.NotifierTest do
  use OmegaBravera.DataCase, async: true

  import OmegaBravera.Factory
  alias OmegaBravera.Accounts.Notifier

  test "user_signup_email/1 builds the signup email for the sendgrid template" do
    user =
      insert(:user, %{
        firstname: "Rafael",
        lastname: "Garcia",
        email: "simon.garciar@gmail.com",
        email_activation_token: "8wqfT-c2L1V1lSRb_2eum3Ep3Tf2bDP4"
      })

    result = Notifier.user_signup_email(user, "b47d2224-792a-43d8-b4b2-f53b033d2f41")

    assert result == %SendGrid.Email{
             __phoenix_layout__: nil,
             __phoenix_view__: nil,
             attachments: nil,
             cc: nil,
             content: nil,
             custom_args: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             substitutions: %{
               "-fullName-" => "Rafael Garcia",
               "-emailVerificationUrl-" =>
                 "https://www.bravera.co/user/account/activate/8wqfT-c2L1V1lSRb_2eum3Ep3Tf2bDP4"
             },
             template_id: "b47d2224-792a-43d8-b4b2-f53b033d2f41",
             to: [%{email: "simon.garciar@gmail.com"}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_user_signup_email/1 sends the user signup email" do
    user = insert(:user)
    result = Notifier.send_user_signup_email(user)

    assert result == :ok
  end
end
