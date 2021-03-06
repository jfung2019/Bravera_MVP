defmodule OmegaBravera.NotifierTest do
  use OmegaBravera.DataCase
  import OmegaBravera.Factory
  alias OmegaBravera.Donations.Notifier

  setup do
    user = insert(:user)
    ngo = insert(:ngo)

    challenge =
      insert(:ngo_challenge, %{
        user: user,
        ngo: ngo,
        status: "pre_registration",
        start_date: Timex.shift(Timex.now(), days: 5)
      })

    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    [
      user: user,
      ngo: ngo,
      challenge: insert(:ngo_challenge, %{user: user, ngo: ngo}),
      pre_registration_challenge: challenge
    ]
  end

  test "participant_email creates the participant email",
       %{challenge: challenge, user: user} = context do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    pledges = donations(context, donor)
    template_id = "79561f40-9939-406c-bdbe-0ecca63a1e1a"

    result =
      Notifier.participant_email(
        challenge,
        donor,
        pledges,
        template_id
      )

    assert result == %SendGrid.Email{
             __phoenix_layout__: nil,
             __phoenix_view__: nil,
             attachments: nil,
             cc: nil,
             content: nil,
             custom_args: nil,
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             substitutions: %{
               "-challengeURL-" => "",
               "-donorName-" => "#{donor.firstname} #{donor.lastname}",
               "-donorPledge-" => "HK$600",
               "-participantName-" => user.firstname
             },
             template_id: template_id,
             to: [%{email: user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "pre_registration_donor_email", %{
    pre_registration_challenge: pre_registration_challenge,
    user: user
  } do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    template_id = "9fc14299-96a0-4a4d-9917-c19f747270ff"

    result =
      Notifier.pre_registration_donor_email(
        pre_registration_challenge,
        donor,
        template_id
      )

    assert result == %SendGrid.Email{
             __phoenix_layout__: nil,
             __phoenix_view__: nil,
             attachments: nil,
             cc: nil,
             content: nil,
             custom_args: nil,
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             substitutions: %{
               "-challengeURL-" => "",
               "-donorName-" => "#{donor.firstname} #{donor.lastname}",
               "-participantName-" => user.firstname,
               "-challengeStartDate-" =>
                 Timex.format!(pre_registration_challenge.start_date, "%Y-%m-%d", :strftime)
             },
             template_id: template_id,
             to: [%{email: donor.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "donor_email", %{challenge: challenge, user: user} do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    template_id = "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986"
    result = Notifier.donor_email(challenge, donor, template_id)

    assert result == %SendGrid.Email{
             __phoenix_layout__: nil,
             __phoenix_view__: nil,
             attachments: nil,
             cc: nil,
             content: nil,
             custom_args: nil,
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             substitutions: %{
               "-challengeURL-" => "",
               "-donorName-" => "#{donor.firstname} #{donor.lastname}",
               "-participantName-" => user.firstname
             },
             template_id: template_id,
             to: [%{email: donor.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "email_parties/4 sends the email to both donor and participant",
       %{challenge: challenge, user: _user} = context do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    pledges = donations(context, donor)

    result = Notifier.email_parties(challenge, donor, pledges)

    assert result == [:ok, :ok]
  end

  test "email_parties/4 sends the email to both donor (pre_registration pledge) and participant",
       %{pre_registration_challenge: pre_registration_challenge, user: _user} = context do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    pledges = donations(context, donor)

    result =
      Notifier.email_parties(
        pre_registration_challenge,
        donor,
        pledges
      )

    assert result == [:ok, :ok]
  end

  test "donation_charged_email" do
    donor =
      insert(:donor, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    donation_params = %{
      donor: donor,
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      card_brand: "Visa",
      charge_id: "ch_1D9L1lEXtHU8QBy8sVLJxp7P",
      charged_amount: Decimal.from_float(10.0),
      charged_description: "Donation to Save the children via Bravera.co",
      charged_status: "succeeded",
      last_digits: "4242",
      charged_at: DateTime.from_unix!(1_536_707_533)
    }

    template_id = "f9448c06-ff05-4901-bb47-f21a7848c1e7"

    result = Notifier.donation_charged_email(insert(:donation, donation_params), template_id)

    assert result == %SendGrid.Email{
             __phoenix_layout__: nil,
             __phoenix_view__: nil,
             attachments: nil,
             cc: nil,
             content: nil,
             custom_args: nil,
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             substitutions: %{
               "-donorName-" => "Mike Dough",
               "-paymentId-" => "ch_1D9L1lEXtHU8QBy8sVLJxp7P",
               "-cardType-" => "Visa",
               "-cardNumber-" => "Card ending in 4242",
               "-donationName-" => "Donation to Save the children via Bravera.co",
               "-donationDate-" => "2018-09-11 23:12:13",
               "-chargedAmount-" => "10 hkd"
             },
             template_id: template_id,
             to: [%{email: donor.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  defp donations(%{ngo: ngo, challenge: challenge}, donor) do
    [
      build(:donation, %{user: donor, ngo: ngo, ngo_chal: challenge}),
      build(:donation, %{
        milestone: 2,
        milestone_distance: 15,
        donor: donor,
        ngo: ngo,
        ngo_chal: challenge
      }),
      build(:donation, %{
        milestone: 3,
        milestone_distance: 25,
        donor: donor,
        ngo: ngo,
        ngo_chal: challenge
      }),
      build(:donation, %{
        milestone: 4,
        milestone_distance: 50,
        donor: donor,
        ngo: ngo,
        ngo_chal: challenge
      })
    ]
  end
end
