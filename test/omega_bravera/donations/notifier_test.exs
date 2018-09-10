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
      bcc: nil,
      cc: nil,
      content: nil,
      custom_args: nil,
      headers: nil,
      reply_to: nil,
      send_at: nil,
      subject: nil,
      from: %{email: "admin@bravera.co"},
      substitutions: %{
        "-challengeURL-" => "http://bravera.co/swcc/John-594",
        "-donorName-" => "#{donor.firstname} #{donor.lastname}",
        "-donorPledge-" => "$40 HKD",
        "-participantName-" => user.firstname
      },
      template_id: "79561f40-9939-406c-bdbe-0ecca63a1e1a",
      to: [%{email: user.email}]
    }
  end


  test "donor_email", %{challenge: challenge, user: user} do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})

    result = Notifier.donor_email(challenge, donor, "/swcc/#{user.firstname}-594")

    assert result == %SendGrid.Email{
      __phoenix_layout__: nil,
      __phoenix_view__: nil,
      attachments: nil,
      bcc: nil,
      cc: nil,
      content: nil,
      custom_args: nil,
      headers: nil,
      reply_to: nil,
      send_at: nil,
      subject: nil,
      from: %{email: "admin@bravera.co"},
      substitutions: %{
        "-challengeURL-" => "http://bravera.co/swcc/John-594",
        "-donorName-" => "#{donor.firstname} #{donor.lastname}",
        "-participantName-" => user.firstname
      },
      template_id: "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986",
      to: [%{email: donor.email}]
    }
  end

  test "email_parties/4 sends the email to both donor and participant", %{challenge: challenge, user: user} = context do
    donor = insert(:user, %{firstname: "Mike", lastname: "Dough", email: "mike.dough@example.com"})
    pledges = donations(context, donor)

    result = Notifier.email_parties(challenge, donor, pledges, "/swcc/#{user.firstname}-594")

    assert result == [:ok, :ok]
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
