defmodule OmegaBravera.Challenges.NotifierTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Challenges.{NGOChal, Notifier}
  alias OmegaBravera.Accounts.User

  test "manual_activity_blocked_email" do
    challenge = insert(:ngo_challenge)

    email = Notifier.manual_activity_blocked_email(challenge, "/swcc/John-512")

    assert email == %SendGrid.Email{
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
              "-challengeLink-" => "https://bravera.co/swcc/John-512",
               "-participantName-" => "John"
             },
             template_id: "fcd40945-8a55-4459-94b9-401a995246fb",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_manual_activity_blocked_email/1 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_manual_activity_blocked_email(challenge, "/swcc/John-512") == :ok
  end

  test "challenge_activated_email" do
    challenge = insert(:ngo_challenge)

    email = Notifier.challenge_activated_email(challenge, "/swcc/John-512")

    assert email == %SendGrid.Email{
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
               "-challengeLink-" => "https://bravera.co/swcc/John-512",
               "-firstName-" => "John"
             },
             template_id: "75516ad9-3ce8-4742-bd70-1227ce3cba1d",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_challenge_activated_email/2 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_challenge_activated_email(challenge, "/swcc/John-582") == :ok
  end

  test "pre_registration_challenge_signup_email" do
    challenge = insert(:ngo_challenge)

    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    email = Notifier.pre_registration_challenge_signup_email(challenge, "/swcc/John-512")

    assert email == %SendGrid.Email{
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
               "-kms-" => "#{challenge.distance_target} Km",
               "-causeName-" => "Save the children worldwide",
               "-challengeLink-" => "https://bravera.co/swcc/John-512",
               "-yearMonthDay-" => Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime),
               "-days-" => "5 days",
               "-firstName-" => "John",
               "-fundraisingGoal-" => "2000"
             },
             template_id: "0e8a21f6-234f-4293-b5cf-fc9805042d82",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_pre_registration_challenge_signup_email/2 sends the email" do
    challenge = insert(:ngo_challenge)

    assert Notifier.send_pre_registration_challenge_sign_up_email(challenge, "/swcc/John-582") ==
             :ok
  end

  test "challenge_signup_email" do
    challenge = insert(:ngo_challenge)

    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    email = Notifier.challenge_signup_email(challenge, "/swcc/John-512")

    assert email == %SendGrid.Email{
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
               "-challengeDistance-" => "#{challenge.distance_target} Km",
               "-challengeMilestones-" => NGOChal.milestones_string(challenge),
               "-challengeName-" => "John-512",
               "-challengeURL-" => "https://bravera.co/swcc/John-512",
               "-startDate-" => Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime),
               "-daysDuration-" => "5 days",
               "-firstName-" => "John",
               "-ngoName-" => "Save the children worldwide"
             },
             template_id: "e5402f0b-a2c2-4786-955b-21d1cac6211d",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_challenge_signup_email/2 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_challenge_signup_email(challenge, "/swcc/John-582") == :ok
  end

  test "activity_completed_email/2" do
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(4.215)})

    activity =
      insert(:activity, %{
        challenge: challenge,
        user: challenge.user,
        distance: Decimal.new(4.215)
      })

    email = Notifier.activity_completed_email(challenge, activity)

    assert email == %SendGrid.Email{
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
               "-firstName-" => "John",
               "-activityDistance-" => "#{Decimal.new(4.215)} Km",
               "-completedChallengeDistance-" => "#{Decimal.new(4.215)} Km",
               "-challengeDistance-" => "#{challenge.distance_target} Km",
               "-timeRemaining-" => "4 days",
               "-challengeURL-" => "https://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}"
             },
             template_id: "d92b0884-818d-4f54-926a-a529e5caa7d8",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_activity_completed_email/2 sends the email" do
    challenge = insert(:ngo_challenge)

    activity =
      insert(:activity, %{
        challenge: challenge,
        user: challenge.user,
        distance: Decimal.new(4.215)
      })

    assert Notifier.send_activity_completed_email(challenge, activity) == :ok
  end

  test "participant_milestone_email/1" do
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(4.215)})

    email = Notifier.participant_milestone_email(challenge)

    assert email == %SendGrid.Email{
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
               "-firstName-" => challenge.user.firstname
             },
             template_id: "e4c626a0-ad9a-4479-8228-6c02e7318789",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
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
             cc: nil,
             content: nil,
             custom_args: nil,
             headers: nil,
             reply_to: nil,
             send_at: nil,
             subject: nil,
             from: %{email: "admin@bravera.co", name: "Bravera"},
             substitutions: %{
               "-donorName-" => donation.user.firstname,
               "-participantName-" => donation.ngo_chal.user.firstname,
               "-challengeURL-" =>
                 "https://bravera.co/#{donation.ngo.slug}/#{donation.ngo_chal.slug}"
             },
             template_id: "c8573175-93a6-4f8c-b1bb-9368ad75981a",
             to: [%{email: donation.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
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

  test "participant_inactivity_email/1" do
    challenge = insert(:ngo_challenge)

    email = Notifier.participant_inactivity_email(challenge)

    assert email == %SendGrid.Email{
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
               "-firstName-" => challenge.user.firstname,
               "-challengeURL-" => "https://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}"
             },
             template_id: "1395a042-ef5a-48a5-b890-c6340dd8eeff",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_participant_inactivity_email/1 sends the email" do
    challenge = insert(:ngo_challenge)
    assert Notifier.send_participant_inactivity_email(challenge) == :ok
  end

  test "donor_inactivity_email/1" do
    challenge = insert(:ngo_challenge)
    donor = insert(:user)

    email = Notifier.donor_inactivity_email(challenge, donor)

    assert email == %SendGrid.Email{
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
               "-donorName-" => donor.firstname,
               "-participantName-" => User.full_name(challenge.user),
               "-challengeURL-" => "https://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}"
             },
             template_id: "b91a66e1-d7f5-404f-804a-9a21f4ec70d4",
             to: [%{email: donor.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_donor_inactivity_email/1 sends the email" do
    challenge = insert(:ngo_challenge)
    donor = insert(:user)
    assert Notifier.send_donor_inactivity_email(challenge, donor) == :ok
  end
end
