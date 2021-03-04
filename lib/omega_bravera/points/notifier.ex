defmodule OmegaBravera.Points.Notifier do
  alias SendGrid.{Mail, Email}

  def send_points_updated_notification_from_org(
        %{firstname: first_name, email: email},
        current_balance,
        points_difference
      ) do
    template_id = "9e9dc774-5599-4c08-b1e6-d76afb60ab22"

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-FirstName-", first_name)
    |> Email.add_substitution("-CurrentBalance-", Decimal.to_string(current_balance, :normal))
    |> Email.add_substitution(
      "-PreviousBalance-",
      Decimal.to_string(Decimal.sub(current_balance, points_difference), :normal)
    )
    |> Email.add_substitution("-value-", Decimal.to_string(points_difference, :normal))
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
    |> Mail.send()
  end
end
