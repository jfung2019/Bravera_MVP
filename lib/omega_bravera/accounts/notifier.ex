defmodule OmegaBravera.Accounts.Notifier do
  alias OmegaBravera.Accounts.User
  alias SendGrid.{Mailer, Email}

  def send_user_signup_email(%User{} = user) do
    user
    |> user_signup_email()
    |> Mailer.send()
  end

  def user_signup_email(%User{} = user) do
    Email.build()
    |> Email.put_template("b47d2224-792a-43d8-b4b2-f53b033d2f41")
    |> Email.add_substitution("-fullName-", User.full_name(user))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end
end
