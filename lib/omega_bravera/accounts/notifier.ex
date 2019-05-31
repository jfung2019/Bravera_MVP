defmodule OmegaBravera.Accounts.Notifier do
  alias OmegaBravera.{Repo, Emails, Accounts.User, Accounts.Credential}
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  alias SendGrid.{Mailer, Email}

  def send_user_signup_email(%User{} = user, redirect_to \\ "/") do
    template_id = "b47d2224-792a-43d8-b4b2-f53b033d2f41"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    user = Repo.preload(user, [:subscribed_email_categories])

    if user_subscribed_in_category?(user.subscribed_email_categories, sendgrid_email.category.id) do
      user
      |> user_signup_email(redirect_to, template_id)
      |> Mailer.send()
    end
  end

  def user_signup_email(%User{} = user, redirect_to, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-fullName-", User.full_name(user))
    |> Email.add_substitution(
      "-emailVerificationUrl-",
      Routes.user_url(Endpoint, :activate_email, user.email_activation_token, %{
        redirect_to: redirect_to
      })
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_password_reset_email(%Credential{} = credential) do
    template_id = "1bfb8b3b-e5fd-4052-baad-55fd4a5f7c2b"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    credential = Repo.preload(credential, user: [:subscribed_email_categories])

    if user_subscribed_in_category?(
         credential.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      credential
      |> password_reset_email(template_id)
      |> Mailer.send()
    end
  end

  def password_reset_email(%Credential{} = credential, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution(
      "-passwordResetUrl-",
      Routes.password_url(Endpoint, :edit, credential)
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(credential.user.email)
    |> IO.inspect()
  end

  defp user_subscribed_in_category?(user_subscribed_categories, email_category_id) do
    # if user_subscribed_categories is empty, it means that user is subscribed in all email_categories.
    if Enum.empty?(user_subscribed_categories) do
      true
    else
      # User actually choose specific categories of emails.
      user_subscribed_categories
      |> Enum.map(& &1.category_id)
      |> Enum.member?(email_category_id)
    end
  end
end
