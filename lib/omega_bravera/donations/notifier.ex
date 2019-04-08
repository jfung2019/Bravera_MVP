defmodule OmegaBravera.Donations.Notifier do
  alias OmegaBravera.{
    Challenges.NGOChal,
    Accounts.Donor,
    Repo,
    Money.Donation,
    Emails,
    Money.Donation
  }

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint
  alias SendGrid.{Email, Mailer}

  def email_parties(%NGOChal{} = chal, %Donor{} = donor, pledges) do
    challenge = Repo.preload(chal, [:ngo, user: [:subscribed_email_categories]])

    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    donor_result = email_donor(challenge, donor)
    participant_result = email_participant(challenge, donor, pledges)

    [donor_result, participant_result]
  end

  def email_participant(%NGOChal{} = challenge, %Donor{} = donor, pledges) do
    template_id = "79561f40-9939-406c-bdbe-0ecca63a1e1a"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> participant_email(donor, pledges, template_id)
      |> Mailer.send()
    end
  end

  def email_donor(%NGOChal{} = challenge, %Donor{} = donor) do
    pre_registration_donor_template_id = "9fc14299-96a0-4a4d-9917-c19f747270ff"
    donor_email_template_id = "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986"

    cond do
      challenge.status == "pre_registration" and
          Timex.after?(challenge.start_date, Timex.now("Asia/Hong_Kong")) ->
        challenge
        |> pre_registration_donor_email(
          donor,
          pre_registration_donor_template_id
        )
        |> Mailer.send()

      true ->
        challenge
        |> donor_email(donor, donor_email_template_id)
        |> Mailer.send()
    end
  end

  def participant_email(
        %NGOChal{} = challenge,
        %Donor{} = donor,
        pledges,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", Donor.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-donorPledge-",
      "#{OmegaBraveraWeb.ViewHelpers.currency_to_symbol(challenge.default_currency)}#{
        pledged_amount(pledges)
      }"
    )
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def pre_registration_donor_email(
        %NGOChal{} = challenge,
        %Donor{} = donor,
        pre_registration_donor_template_id
      ) do
    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    Email.build()
    |> Email.put_template(pre_registration_donor_template_id)
    |> Email.add_substitution("-donorName-", Donor.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-challengeStartDate-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def donor_email(
        %NGOChal{} = challenge,
        %Donor{} = donor,
        donor_email_template_id
      ) do
    Email.build()
    |> Email.put_template(donor_email_template_id)
    |> Email.add_substitution("-donorName-", Donor.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def send_donation_charged_email(%Donation{} = donation) do
    template_id = "f9448c06-ff05-4901-bb47-f21a7848c1e7"

    donation
    |> Repo.preload([:donor])
    |> donation_charged_email(template_id)
    |> Mailer.send()
  end

  def donation_charged_email(%Donation{} = donation, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", Donor.full_name(donation.donor))
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
    |> Email.add_to(donation.donor.email)
  end

  defp challenge_url(challenge) do
    Routes.ngo_ngo_chal_url(Endpoint, :show, challenge.ngo.slug, challenge.slug)
  end

  defp pledged_amount(pledges) when is_list(pledges),
    do:
      Enum.reduce(pledges, Decimal.new(0), fn pledge, acc -> Decimal.add(acc, pledge.amount) end)

  defp pledged_amount(%Donation{amount: amount}), do: Decimal.new(amount)

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
