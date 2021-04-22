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
        email_activation_token: OmegaBravera.Accounts.Shared.gen_user_activate_email_token()
      })

    result = Notifier.user_signup_email(user, "d-1dc516c092744a15a0f5b1430962fa0d")

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
             dynamic_template_data: %{
               "code" => user.email_activation_token,
               "firstName" => "Rafael Garcia"
             },
             template_id: "d-1dc516c092744a15a0f5b1430962fa0d",
             to: [%{email: "simon.garciar@gmail.com"}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_user_signup_email/1 sends the user signup email" do
    user = insert(:user, %{email_activation_token: "8wqfT-c2L1V1lSRb_2eum3Ep3Tf2bDP4"})
    result = Notifier.send_user_signup_email(user)

    assert result == :ok
  end
end
