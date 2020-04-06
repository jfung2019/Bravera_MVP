defmodule OmegaBravera.Challenges.Notifier do
  alias OmegaBravera.{
    Challenges.NGOChal,
    Repo,
    Money.Donation,
    Accounts.User,
    Accounts.Donor,
    Emails
  }
  alias OmegaBravera.Activity.ActivityAccumulator
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint
  alias SendGrid.{Email, Mail}
  import OmegaBravera.Emails, only: [user_subscribed_in_category?: 2]

  def send_manual_activity_blocked_email(%NGOChal{} = challenge) do
    template_id = "fcd40945-8a55-4459-94b9-401a995246fb"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> manual_activity_blocked_email(template_id)
      |> Mail.send()
    end
  end

  def manual_activity_blocked_email(%NGOChal{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-participantName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_challenge_activated_email(%NGOChal{} = challenge) do
    template_id = "75516ad9-3ce8-4742-bd70-1227ce3cba1d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> challenge_activated_email(template_id)
      |> Mail.send()
    end
  end

  def challenge_activated_email(%NGOChal{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_pre_registration_challenge_sign_up_email(%NGOChal{} = challenge) do
    template_id = "0e8a21f6-234f-4293-b5cf-fc9805042d82"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> pre_registration_challenge_signup_email(template_id)
      |> Mail.send()
    end
  end

  def pre_registration_challenge_signup_email(%NGOChal{} = challenge, template_id) do
    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.add_substitution(
      "-yearMonthDay-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-causeName-", challenge.ngo.name)
    |> Email.add_substitution("-days-", "#{challenge.duration} days")
    |> Email.add_substitution("-kms-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-fundraisingGoal-", "#{challenge.money_target}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_challenge_signup_email(%NGOChal{} = challenge) do
    template_id = "e5402f0b-a2c2-4786-955b-21d1cac6211d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> challenge_signup_email(template_id)
      |> Mail.send()
    end
  end

  def challenge_signup_email(%NGOChal{} = challenge, template_id) do
    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.add_substitution(
      "-startDate-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-challengeName-", challenge.slug)
    |> Email.add_substitution("-ngoName-", challenge.ngo.name)
    |> Email.add_substitution("-daysDuration-", "#{challenge.duration} days")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-challengeMilestones-", "#{NGOChal.milestones_string(challenge)}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_activity_completed_email(%NGOChal{} = challenge, %ActivityAccumulator{} = activity) do
    template_id = "d92b0884-818d-4f54-926a-a529e5caa7d8"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> activity_completed_email(activity, template_id)
      |> Mail.send()
    end
  end

  def activity_completed_email(
        %NGOChal{} = challenge,
        %ActivityAccumulator{} = activity,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-activityDistance-", "#{Decimal.round(activity.distance, 2)} Km")
    |> Email.add_substitution(
      "-completedChallengeDistance-",
      "#{Decimal.round(challenge.distance_covered, 2)} Km"
    )
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-timeRemaining-", "#{remaining_time(challenge)}")
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_donor_milestone_email(%Donation{} = donation) do
    template_id = "c8573175-93a6-4f8c-b1bb-9368ad75981a"

    donation
    |> Repo.preload([:donor, ngo_chal: [:ngo, :user]])
    |> donor_milestone_email(template_id)
    |> Mail.send()
  end

  def donor_milestone_email(%Donation{} = donation, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", donation.donor.firstname)
    |> Email.add_substitution("-participantName-", donation.ngo_chal.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(donation.ngo_chal))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donation.donor.email)
  end

  def send_participant_milestone_email(%NGOChal{} = challenge) do
    template_id = "e4c626a0-ad9a-4479-8228-6c02e7318789"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> participant_milestone_email(template_id)
      |> Mail.send()
    end
  end

  def participant_milestone_email(%NGOChal{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_participant_inactivity_email(%NGOChal{} = challenge) do
    template_id = "1395a042-ef5a-48a5-b890-c6340dd8eeff"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:ngo, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> participant_inactivity_email(template_id)
      |> Mail.send()
    end
  end

  def participant_inactivity_email(%NGOChal{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_donor_inactivity_email(%NGOChal{} = challenge, %Donor{} = donor) do
    template_id = "b91a66e1-d7f5-404f-804a-9a21f4ec70d4"

    challenge
    |> Repo.preload([:user, :ngo])
    |> donor_inactivity_email(donor, template_id)
    |> Mail.send()
  end

  def donor_inactivity_email(%NGOChal{} = challenge, %Donor{} = donor, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-donorName-", donor.firstname)
    |> Email.add_substitution("-participantName-", User.full_name(challenge.user))
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def send_team_members_invite_email(%NGOChal{} = challenge, team_member) do
    # TODO: allow a team invitee to stop team owners from emailing him. -Sherief
    template_id = "e1869afd-8cd1-4789-b444-dabff9b7f3f1"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:team, :ngo, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> team_member_invite_email(team_member, template_id)
      |> Mail.send()
    end
  end

  def team_member_invite_email(
        %NGOChal{} = challenge,
        %{
          invitee_name: invitee_name,
          token: token,
          email: email
        },
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-inviteeName-", invitee_name)
    |> Email.add_substitution("-teamOwnerName-", User.full_name(challenge.user))
    |> Email.add_substitution("-ngoName-", challenge.ngo.name)
    |> Email.add_substitution("-teamInvitationLink-", team_member_invite_link(challenge, token))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
  end

  def team_member_invite_email(_, _) do
  end

  def send_team_owner_member_added_notification(%NGOChal{} = challenge, %User{} = user) do
    template_id = "0f853118-211f-429f-8975-12f88c937855"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, user: [:subscribed_email_categories])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> team_owner_member_added_notification_email(user, template_id)
      |> Mail.send()
    end
  end

  def team_owner_member_added_notification_email(
        %NGOChal{} = challenge,
        %User{} = user,
        template_id
      ) do
    challenge = %{
      challenge
      | start_date: Timex.to_datetime(challenge.start_date, "Asia/Hong_Kong")
    }

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-teamOwnerName-", User.full_name(challenge.user))
    |> Email.add_substitution("-inviteeName-", User.full_name(user))
    |> Email.add_substitution("-ngoName-", challenge.ngo.name)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.add_substitution(
      "-startDate-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-daysDuration-", "#{challenge.duration}")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-challengeMilestones-", "#{NGOChal.milestones_string(challenge)}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_buddies_invite_email(%NGOChal{} = challenge, buddies) do
    buddies
    |> Enum.map(&buddy_invite_email(challenge, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.each(&Mail.send/1)
  end

  def buddy_invite_email(%NGOChal{} = challenge, %{"name" => name, "email" => email})
      when not is_nil(name) and not is_nil(email) and name != "" and email != "" do
    Email.build()
    |> Email.put_template("58de1c57-8028-4e0d-adb2-7349c01cf233")
    |> Email.add_substitution("-buddyName-", name)
    |> Email.add_substitution("-participantName-", User.full_name(challenge.user))
    |> Email.add_substitution("-participantFirstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
  end

  def buddy_invite_email(_, _) do
  end

  defp challenge_url(challenge) do
    Routes.ngo_ngo_chal_url(Endpoint, :show, challenge.ngo.slug, challenge.slug)
  end

  defp team_member_invite_link(challenge, token) do
    Routes.ngo_ngo_chal_ngo_chal_url(
      Endpoint,
      :add_team_member,
      challenge.ngo.slug,
      challenge.slug,
      token
    )
  end

  defp remaining_time(%NGOChal{end_date: end_date}) do
    now = Timex.now("Asia/Hong_Kong")
    end_date = end_date |> Timex.to_datetime("Asia/Hong_Kong")

    cond do
      (diff = Timex.diff(end_date, now, :days)) > 0 ->
        "#{diff} days"

      (diff = Timex.diff(end_date, now, :hours)) > 0 ->
        "#{diff} hours"

      (diff = Timex.diff(end_date, now, :minutes)) > 0 ->
        "#{diff} minutes"

      true ->
        "0 minutes"
    end
  end
end
