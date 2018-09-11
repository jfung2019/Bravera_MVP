defmodule OmegaBravera.Donations.Notifier do
  alias OmegaBravera.{Challenges.NGOChal, Accounts.User, Repo, Donations.Pledges, Money.Donation}
  alias SendGrid.{Email, Mailer}

  def email_parties(%NGOChal{} = chal, %User{} = donor, pledges, challenge_path) do
    challenge = Repo.preload(chal, [:user, :ngo])

    donor_result = email_donor(challenge, donor, challenge_path)
    participant_result = email_participant(challenge, donor, pledges, challenge_path)

    [donor_result, participant_result]
  end

  def email_participant(%NGOChal{} = challenge, %User{} = donor, pledges, challenge_path) do
    challenge
    |> participant_email(donor, pledges, challenge_path)
    |> Mailer.send()
  end

  def email_donor(%NGOChal{} = challenge, %User{} = donor, challenge_path) do
    challenge
    |> donor_email(donor, challenge_path)
    |> Mailer.send()
  end

  #TODO: Change harcoded HKD to pledged currency when supporting other currencies - Simon
  def participant_email(%NGOChal{} = challenge, %User{} = donor, pledges, challenge_path) do
    Email.build()
    |> Email.put_template("79561f40-9939-406c-bdbe-0ecca63a1e1a")
    |> Email.add_substitution("-donorName-", User.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution("-donorPledge-", "$#{pledged_amount(pledges)} HKD")
    |> Email.add_substitution("-challengeURL-", "http://bravera.co#{challenge_path}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_to(challenge.user.email)
  end

  def donor_email(%NGOChal{} = challenge, %User{} = donor, challenge_path) do
    Email.build()
    |> Email.put_template("4ab4a0f8-79ac-4f82-9ee2-95db6fafb986")
    |> Email.add_substitution("-donorName-", User.full_name(donor))
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", "http://bravera.co#{challenge_path}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_to(donor.email)
  end

  def send_donation_charged_email(%Donation{} = donation) do
    donation
    |> Repo.preload([:user])
    |> donation_charged_email()
    |> Mailer.send()
  end

  def donation_charged_email(%Donation{} = donation) do
    Email.build()
    |> Email.put_template("f9448c06-ff05-4901-bb47-f21a7848c1e7")
    |> Email.add_substitution("-donorName-", User.full_name(donation.user))
    |> Email.add_substitution("-paymentId-", donation.charge_id)
    |> Email.add_substitution("-cardType-", donation.card_brand)
    |> Email.add_substitution("-cardNumber-", "Card ending in #{donation.last_digits}")
    |> Email.add_substitution("-donationName-", donation.charged_description)
    |> Email.add_substitution("-donationDate-", Timex.format!(donation.charged_at, "%Y-%m-%d %H:%M:%S", :strftime))
    |> Email.add_substitution("-chargedAmount-", "#{donation.charged_amount} #{donation.currency}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_to(donation.user.email)
  end

  defp pledged_amount(pledges), do: Enum.reduce(pledges, Decimal.new(0), fn(pledge, acc) -> Decimal.add(acc, pledge.amount) end)
end
