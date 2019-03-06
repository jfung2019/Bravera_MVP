defmodule OmegaBravera.Donations.Notifier do
  alias OmegaBravera.{Challenges.NGOChal, Accounts.User, Repo, Money.Donation, Emails}
  alias SendGrid.{Email, Mailer}

  def email_parties(%NGOChal{} = chal, %User{} = donor, pledges, challenge_path) do
    challenge = Repo.preload(chal, [:ngo, user: [:subscribed_email_categories]])

    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    donor_result = email_donor(challenge, donor, challenge_path)
    participant_result = email_participant(challenge, donor, pledges, challenge_path)

    [donor_result, participant_result]
  end

  def email_participant(%NGOChal{} = challenge, %User{} = donor, pledges, challenge_path) do
    template_id = "79561f40-9939-406c-bdbe-0ecca63a1e1a"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)

    if user_subscribed_in_category?(challenge.user.subscribed_email_categories, sendgrid_email.category.id) do
      challenge
      |> participant_email(donor, pledges, challenge_path, template_id)
      |> Mailer.send()
    end
  end

  def email_donor(%NGOChal{} = challenge, %User{} = donor, challenge_path) do
    pre_registration_donor_template_id = "9fc14299-96a0-4a4d-9917-c19f747270ff"
    donor_email_template_id = "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986"

    pre_registration_donor_sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(pre_registration_donor_template_id)
    donor_email_template_id_sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(donor_email_template_id)

    donor = Repo.preload(donor, [:subscribed_email_categories])

    cond do
      challenge.status == "pre_registration" and Timex.after?(challenge.start_date, Timex.now("Asia/Hong_Kong")) ->
        if user_subscribed_in_category?(donor.subscribed_email_categories, donor_email_template_id_sendgrid_email.category.id) do
          challenge
          |> pre_registration_donor_email(donor, challenge_path, pre_registration_donor_template_id)
          |> Mailer.send()
        end

      true ->
        if user_subscribed_in_category?(donor.subscribed_email_categories, pre_registration_donor_sendgrid_email.category.id) do
          challenge
          |> donor_email(donor, challenge_path, donor_email_template_id)
          |> Mailer.send()
        end
    end
  end

  def participant_email(%NGOChal{} = challenge, %User{} = donor, pledges, challenge_path, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", User.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-donorPledge-",
      "#{OmegaBraveraWeb.ViewHelpers.currency_to_symbol(challenge.default_currency)}#{
        pledged_amount(pledges)
      }"
    )
    |> Email.add_substitution(
      "-challengeURL-",
      "#{Application.get_env(:omega_bravera, :app_base_url)}#{challenge_path}"
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def pre_registration_donor_email(%NGOChal{} = challenge, %User{} = donor, challenge_path, pre_registration_donor_template_id) do
    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    Email.build()
    |> Email.put_template(pre_registration_donor_template_id)
    |> Email.add_substitution("-donorName-", User.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-challengeStartDate-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution(
      "-challengeURL-",
      "#{Application.get_env(:omega_bravera, :app_base_url)}#{challenge_path}"
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def donor_email(%NGOChal{} = challenge, %User{} = donor, challenge_path, donor_email_template_id) do
    Email.build()
    |> Email.put_template(donor_email_template_id)
    |> Email.add_substitution("-donorName-", User.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-challengeURL-",
      "#{Application.get_env(:omega_bravera, :app_base_url)}#{challenge_path}"
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def send_donation_charged_email(%Donation{} = donation) do
    template_id = "f9448c06-ff05-4901-bb47-f21a7848c1e7"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    donation = Repo.preload(donation, [user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(donation.user.subscribed_email_categories, sendgrid_email.category.id) do
      donation
      |> donation_charged_email(template_id)
      |> Mailer.send()
    end
  end

  def donation_charged_email(%Donation{} = donation, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", User.full_name(donation.user))
    |> Email.add_substitution("-paymentId-", donation.charge_id)
    |> Email.add_substitution("-cardType-", donation.card_brand)
    |> Email.add_substitution("-cardNumber-", "Card ending in #{donation.last_digits}")
    |> Email.add_substitution("-donationName-", donation.charged_description)
    |> Email.add_substitution(
      "-donationDate-",
      Timex.format!(donation.charged_at, "%Y-%m-%d %H:%M:%S", :strftime)
    )
    |> Email.add_substitution(
      "-chargedAmount-",
      "#{Decimal.round(donation.charged_amount)} #{donation.currency}"
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donation.user.email)
  end

  defp pledged_amount(pledges),
    do:
      Enum.reduce(pledges, Decimal.new(0), fn pledge, acc -> Decimal.add(acc, pledge.amount) end)

  defp user_subscribed_in_category?(user_subscribed_categories, email_category_id) do
    # if user_subscribed_categories is empty, it means that user is subscribed in all email_categories.
    if Enum.empty?(user_subscribed_categories) do
      true
    else
      # User actually choose specific categories of emails.
      user_subscribed_categories
      |> Enum.map(&(&1.category_id))
      |> Enum.member?(email_category_id)
    end
  end
end
