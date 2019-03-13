defmodule OmegaBravera.Challenges.NotifierTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Challenges.{NGOChal, Notifier}
  alias OmegaBravera.Accounts.User

  test "team_owner_member_added_notification_email" do
    team = insert(:team)
    user = insert(:user)
    insert(:team_member, %{team_id: team.id, user_id: user.id})

    challenge = %{
      team.challenge
      | start_date: Timex.to_datetime(team.challenge.start_date, "Asia/Hong_Kong")
    }

    email =
      Notifier.team_owner_member_added_notification_email(
        challenge,
        user,
        "0f853118-211f-429f-8975-12f88c937855"
      )

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
               "-teamOwnerName-" => "#{User.full_name(challenge.user)}",
               "-inviteeName-" => "#{User.full_name(user)}",
               "-challengeDistance-" => "#{challenge.distance_target} Km",
               "-ngoName-" => "Save the children worldwide",
               "-challengeURL-" =>
                 "https://bravera.co/#{team.challenge.ngo.slug}/#{team.challenge.slug}",
               "-startDate-" => "#{Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)}",
               "-challengeMilestones-" => "#{NGOChal.milestones_string(challenge)}",
               "-daysDuration-" => "#{challenge.duration}"
             },
             template_id: "0f853118-211f-429f-8975-12f88c937855",
             to: [%{email: challenge.user.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_team_owner_member_added_notification/2 sends the email" do
    team = insert(:team)
    user = insert(:user)
    insert(:team_member, %{team_id: team.id, user_id: user.id})

    assert Notifier.send_team_owner_member_added_notification(team.challenge, user) == :ok
  end

  test "team_member_invite_email" do
    invitation = insert(:team_invitation)

    email = Notifier.team_member_invite_email(invitation.team.challenge, invitation)

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
               "-inviteeName-" => invitation.invitee_name,
               "-teamOwnerName-" => "John Doe",
               "-ngoName-" => invitation.team.challenge.ngo.name,
               "-teamInvitationLink-" =>
                 "https://bravera.co/login?team_invitation=/#{invitation.team.challenge.ngo.slug}/#{
                   invitation.team.challenge.slug
                 }/add_team_member/#{invitation.token}"
             },
             template_id: "e1869afd-8cd1-4789-b444-dabff9b7f3f1",
             to: [%{email: invitation.email}],
             bcc: [%{email: "admin@bravera.co"}]
           }
  end

  test "send_team_members_invite_email/2" do
    invitation = insert(:team_invitation)

    assert Notifier.send_team_members_invite_email(invitation.team.challenge, invitation) == :ok
  end

  test "manual_activity_blocked_email" do
    challenge = insert(:ngo_challenge)

    email =
      Notifier.manual_activity_blocked_email(
        challenge,
        "/swcc/John-512",
        "fcd40945-8a55-4459-94b9-401a995246fb"
      )

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

    email =
      Notifier.challenge_activated_email(
        challenge,
        "/swcc/John-512",
        "75516ad9-3ce8-4742-bd70-1227ce3cba1d"
      )

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

    email =
      Notifier.pre_registration_challenge_signup_email(
        challenge,
        "/swcc/John-512",
        "0e8a21f6-234f-4293-b5cf-fc9805042d82"
      )

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

    email =
      Notifier.challenge_signup_email(
        challenge,
        "/swcc/#{challenge.slug}",
        "e5402f0b-a2c2-4786-955b-21d1cac6211d"
      )

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
               "-challengeName-" => "#{challenge.slug}",
               "-challengeURL-" => "https://bravera.co/swcc/#{challenge.slug}",
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
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.from_float(4.215)})

    activity =
      insert(:activity, %{
        challenge: challenge,
        user: challenge.user,
        distance: Decimal.from_float(4.215)
      })

    email =
      Notifier.activity_completed_email(
        challenge,
        activity,
        "d92b0884-818d-4f54-926a-a529e5caa7d8"
      )

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
               "-activityDistance-" => "4 Km",
               "-completedChallengeDistance-" => "#{Decimal.from_float(4.215)} Km",
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
        distance: Decimal.from_float(4.215)
      })

    assert Notifier.send_activity_completed_email(challenge, activity) == :ok
  end

  test "participant_milestone_email/1" do
    challenge = insert(:ngo_challenge, %{distance_covered: Decimal.from_float(4.215)})

    email =
      Notifier.participant_milestone_email(challenge, "e4c626a0-ad9a-4479-8228-6c02e7318789")

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

    email = Notifier.donor_milestone_email(donation, "c8573175-93a6-4f8c-b1bb-9368ad75981a")

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

    email =
      Notifier.participant_inactivity_email(challenge, "1395a042-ef5a-48a5-b890-c6340dd8eeff")

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

    email =
      Notifier.donor_inactivity_email(challenge, donor, "b91a66e1-d7f5-404f-804a-9a21f4ec70d4")

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
