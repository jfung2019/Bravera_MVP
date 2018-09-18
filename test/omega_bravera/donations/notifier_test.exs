defmodule OmegaBravera.NotifierTest do
  use OmegaBravera.DataCase
  import OmegaBravera.Factory

  alias OmegaBravera.Donations.Notifier

  setup do
    user = insert(:user)
    ngo = insert(:ngo)
    [user: user, ngo: ngo, challenge: insert(:ngo_challenge, %{user: user, ngo: ngo})]
  end

  test "participant_email creates the participant email", %{challenge: challenge, user: user} = context do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})
    pledges = donations(context, donor)

    result = Notifier.participant_email(challenge, donor, pledges, "/swcc/#{user.firstname}-594")
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
        "-challengeURL-" => "https://bravera.co/swcc/John-594",
        "-donorName-" => "#{donor.firstname} #{donor.lastname}",
        "-donorPledge-" => "$40 HKD",
        "-participantName-" => user.firstname
      },
      template_id: "79561f40-9939-406c-bdbe-0ecca63a1e1a",
      to: [%{email: user.email}],
      bcc: [%{email: "admin@bravera.co"}]
    }
  end


  test "donor_email", %{challenge: challenge, user: user} do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    result = Notifier.donor_email(challenge, donor, "/swcc/#{user.firstname}-594")

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
        "-challengeURL-" => "https://bravera.co/swcc/John-594",
        "-donorName-" => "#{donor.firstname} #{donor.lastname}",
        "-participantName-" => user.firstname
      },
      template_id: "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986",
      to: [%{email: donor.email}],
      bcc: [%{email: "admin@bravera.co"}]
    }
  end

  test "email_parties/4 sends the email to both donor and participant", %{challenge: challenge, user: user} = context do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})
    pledges = donations(context, donor)

    result = Notifier.email_parties(challenge, donor, pledges, "/swcc/#{user.firstname}-594")

    assert result == [:ok, :ok]
  end


  test "donation_charged_email" do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    donation_params = %{
      user: donor,
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      card_brand: "Visa",
      charge_id: "ch_1D9L1lEXtHU8QBy8sVLJxp7P",
      charged_amount: Decimal.new(10.0),
      charged_description: "Donation to Save the children via Bravera.co",
      charged_status: "succeeded",
      last_digits: "4242",
      charged_at: DateTime.from_unix!(1536707533)
    }

    result = Notifier.donation_charged_email(insert(:donation, donation_params))

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
        "-chargedAmount-" => "10.0 HKD"
      },
      template_id: "f9448c06-ff05-4901-bb47-f21a7848c1e7",
      to: [%{email: donor.email}],
      bcc: [%{email: "admin@bravera.co"}]
    }
  end

  defp donations(%{ngo: ngo, challenge: challenge}, donor) do
    [
      build(:donation, %{user: donor, ngo: ngo, ngo_chal: challenge}),
      build(:donation, %{milestone: 2, milestone_distance: 15, user: donor, ngo: ngo, ngo_chal: challenge}),
      build(:donation, %{milestone: 3, milestone_distance: 25, user: donor, ngo: ngo, ngo_chal: challenge}),
      build(:donation, %{milestone: 4, milestone_distance: 50, user: donor, ngo: ngo, ngo_chal: challenge})
    ]
  end
end
