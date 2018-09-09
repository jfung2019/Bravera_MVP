defmodule OmegaBravera.Challenges.NotifierTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Challenges.{NGOChal, Notifier}

  test "challenge_signup_email" do
    challenge = insert(:ngo_challenge)

    email = Notifier.challenge_signup_email(challenge, "/swcc/John-512")

    assert email == %SendGrid.Email{
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
        "-challengeDistance-" => "#{challenge.distance_target} Km",
        "-challengeMilestones-" => NGOChal.milestones_string(challenge),
        "-challengeName-" => "John-512",
        "-challengeURL-" => "http://bravera.co/swcc/John-512",
        "-startDate-" => Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime),
        "-daysDuration-" => "5 days",
        "-firstName-" => "John",
        "-ngoName-" => "Save the children worldwide"
      },
      template_id: "e5402f0b-a2c2-4786-955b-21d1cac6211d",
      to: [%{email: challenge.user.email}]
    }
  end

  test "send_challenge_signup_email/2 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_challenge_signup_email(challenge, "/swcc/John-582") == :ok
  end


  test "activity_completed_email/2" do
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(4.215)})

    email = Notifier.activity_completed_email(challenge, %Strava.Activity{distance: 4215})

    assert email == %SendGrid.Email{
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
        "-firstName-" => "John",
        "-activityDistance-" => "#{Decimal.new(4.215)} Km",
        "-completedChallengeDistance-" => "#{Decimal.new(4.215)} Km",
        "-challengeDistance-" => "#{challenge.distance_target} Km",
        "-timeRemaining-" => "4 days",
        "-challengeURL-" => "http://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}",
      },
      template_id: "d92b0884-818d-4f54-926a-a529e5caa7d8",
      to: [%{email: challenge.user.email}]
    }
  end

  test "send_activity_completed_email/2 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_activity_completed_email(challenge, %Strava.Activity{distance: 4215}) == :ok
  end

  test "participant_milestone_email/1" do
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(4.215)})

    email = Notifier.participant_milestone_email(challenge)

    assert email == %SendGrid.Email{
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
        "-firstName-" => challenge.user.firstname,
      },
      template_id: "e4c626a0-ad9a-4479-8228-6c02e7318789",
      to: [%{email: challenge.user.email}]
    }
  end

  test "send_participant_milestone_email/1 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_participant_milestone_email(challenge) == :ok
  end

  test "donor_milestone_email/1" do
    user = insert(:user)
    ngo = insert(:ngo, %{slug: "swcc-1"})
    donor = insert(:user)
    challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})
    donation = insert(:donation, %{ngo_chal: challenge, ngo: ngo, user: donor})

    email = Notifier.donor_milestone_email(donation)

    assert email == %SendGrid.Email{
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
        "-donorName-" => donation.user.firstname,
        "-participantName-" => donation.ngo_chal.user.firstname,
        "-challengeURL-" => "http://bravera.co/#{donation.ngo.slug}/#{donation.ngo_chal.slug}"
      },
      template_id: "c8573175-93a6-4f8c-b1bb-9368ad75981a",
      to: [%{email: donation.user.email}]
    }
  end

  test "send_donor_milestone_email/1 sends the email" do
    user = insert(:user)
    ngo = insert(:ngo, %{slug: "swcc-1"})
    donor = insert(:user)
    challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})
    donation = insert(:donation, %{ngo_chal: challenge, ngo: ngo, user: donor})

    assert Notifier.send_donor_milestone_email(donation) == :ok
  end
end
