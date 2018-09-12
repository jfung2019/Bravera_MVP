defmodule OmegaBravera.Accounts.Notifier do

  alias OmegaBravera.Accounts.User
  alias SendGrid.{Mailer, Email}

  def send_signups_digest(params) do
    params
    |> signups_digest_email()
    |> Mailer.send()
  end

  def signups_digest_email(%{users_count: users_amount, csv: csv}) do
    Email.build()
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.put_subject("User signups digest")
    |> Email.put_text("In the past 24h we've had #{users_amount} signups, attached is a CSV with their details")
    |> Email.add_attachment(%{content: Base.encode64(csv), filename: "signups_#{yesterday}.csv"})
    |> Email.add_to("admin@bravera.co")
  end

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
    |> Email.add_to(user.email)
  end

  defp yesterday, do: Timex.shift(Timex.today(), days: -1)
end
