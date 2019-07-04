defmodule OmegaBravera.Offers.Notifier do
  alias OmegaBravera.{
    Offers.OfferChallenge,
    Repo,
    Emails,
    Offers.OfferRedeem,
    Offers.OfferVendor,
    Accounts.User,
    Offers
  }

  alias OmegaBravera.Activity.ActivityAccumulator

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  alias SendGrid.{Email, Mailer}

  def send_challenge_activated_email(%OfferChallenge{} = challenge) do
    template_id = "75516ad9-3ce8-4742-bd70-1227ce3cba1d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> challenge_activated_email(template_id)
      |> Mailer.send()
    end
  end

  def challenge_activated_email(%OfferChallenge{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_team_owner_member_added_notification(%OfferChallenge{} = challenge, %User{} = user) do
    template_id = "4726b363-9a6a-4953-bfac-942cae457053"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, user: [:subscribed_email_categories])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> team_owner_member_added_notification_email(user, template_id)
      |> Mailer.send()
    end
  end

  def team_owner_member_added_notification_email(
        %OfferChallenge{} = challenge,
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
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.add_substitution(
      "-startDate-",
      Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-daysDuration-", challenge_duration(challenge))
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_team_members_invite_email(%OfferChallenge{} = challenge, team_member) do
    # TODO: allow a team invitee to stop team owners from emailing him. -Sherief
    template_id = "e1869afd-8cd1-4789-b444-dabff9b7f3f1"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:team, :offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> team_member_invite_email(team_member, template_id)
      |> Mailer.send()
    end
  end

  def team_member_invite_email(
        %OfferChallenge{} = challenge,
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
    |> Email.add_substitution("-teamInvitationLink-", team_member_invite_link(challenge, token))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
  end

  def team_member_invite_email(_, _, _) do
  end

  def send_reward_vendor_redemption_successful_confirmation(
        %OfferChallenge{} = challenge,
        %OfferRedeem{} = redeem
      ) do
    template_id = "0fd2f256-354f-480a-9b3e-502300da6366"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])
    redeem = Repo.preload(redeem, [:offer_reward, :vendor])
    redeems_count = Offers.get_offer_completed_redeems_count_by_offer_id(challenge.offer_id)

    if not is_nil(sendgrid_email) and not is_nil(redeem.vendor.email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> Repo.preload(:offer)
      |> reward_vendor_redemption_successful_confirmation_email(
        redeem,
        redeems_count,
        template_id
      )
      |> Mailer.send()
    end
  end

  def reward_vendor_redemption_successful_confirmation_email(
        %OfferChallenge{} = challenge,
        %OfferRedeem{} = redeem,
        redeems_count,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution(
      "-redeemDateTime-",
      Timex.format!(redeem.updated_at, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-challengeName-", challenge.offer.name)
    |> Email.add_substitution("-participantFirstName-", challenge.user.firstname)
    |> Email.add_substitution("-productName-", redeem.offer_reward.name)
    |> Email.add_substitution("-redeemID-", Integer.to_string(redeem.id))
    |> Email.add_substitution("-redeemCount-", Integer.to_string(redeems_count))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(redeem.vendor.email)
    |> add_cc(redeem.vendor)
  end

  def send_user_reward_redemption_successful(%OfferChallenge{} = challenge, %User{} = user) do
    template_id = "ea31089b-9507-4b79-a10e-3e763a1b0757"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> Repo.preload(:offer)
      |> user_reward_redemption_successful_email(user, template_id)
      |> Mailer.send()
    end
  end

  def user_reward_redemption_successful_email(
        %OfferChallenge{} = challenge,
        %User{} = user,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_reward_completion_email(
        %OfferChallenge{} = challenge,
        %User{} = user,
        %OfferRedeem{} = offer_redeem
      ) do
    template_id = "42873800-965d-4e0d-bcea-4c59a1934d80"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> Repo.preload(:offer)
      |> reward_completion_email(user, offer_redeem, template_id)
      |> Mailer.send()
    end
  end

  def send_reward_completion_email(_, _, _), do: :error

  def reward_completion_email(
        %OfferChallenge{} = challenge,
        %User{} = user,
        %OfferRedeem{} = offer_redeem,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-offerName-", challenge.offer.name)
    |> Email.add_substitution("-challengeLink-", new_challenge_url(challenge))
    |> Email.add_substitution("-qrCode-", challenge_qr_code_url(challenge, offer_redeem))
    |> Email.add_substitution("-terms-", challenge.offer.toc)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_pre_registration_challenge_sign_up_email(%OfferChallenge{} = challenge) do
    template_id = "75c0cbaa-5f00-410f-b0cc-4167c895d381"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> pre_registration_challenge_signup_email(template_id)
      |> Mailer.send()
    end
  end

  def pre_registration_challenge_signup_email(%OfferChallenge{} = challenge, template_id) do
    start_date = Timex.to_datetime(challenge.offer.start_date, "Asia/Hong_Kong")
    end_date = Timex.to_datetime(challenge.offer.end_date, "Asia/Hong_Kong")

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-ChallengeLink-", challenge_url(challenge))
    |> Email.add_substitution(
      "-StartDate-",
      Timex.format!(start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution(
      "-EndDate-",
      Timex.format!(end_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-ChallengeName-", challenge.offer.name)
    |> Email.add_substitution("-Duration-", "#{get_offer_duration(challenge)} days")
    |> Email.add_substitution("-Distance-", "#{challenge.distance_target} Km")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_team_challenge_signup_email(%OfferChallenge{} = challenge, %User{} = user) do
    template_id = "491c1bf7-1b32-4f90-969c-5147d8fddeea"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> team_challenge_signup_email(user, template_id)
      |> Mailer.send()
    end
  end

  def team_challenge_signup_email(%OfferChallenge{} = challenge, %User{} = user, template_id) do
    start_date = Timex.to_datetime(challenge.offer.start_date, "Asia/Hong_Kong")
    end_date = Timex.to_datetime(challenge.offer.end_date, "Asia/Hong_Kong")

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-ChallengeLink-", challenge_url(challenge))
    |> Email.add_substitution(
      "-StartDate-",
      Timex.format!(start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution(
      "-EndDate-",
      Timex.format!(end_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-ChallengeName-", challenge.offer.name)
    |> Email.add_substitution("-Duration-", "#{get_offer_duration(challenge)} days")
    |> Email.add_substitution("-Distance-", "#{challenge.distance_target} Km")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_challenge_signup_email(%OfferChallenge{} = challenge, %User{} = user) do
    template_id = "34c53203-5dd3-4de3-8ae9-4a6abd52be9d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> challenge_signup_email(user, template_id)
      |> Mailer.send()
    end
  end

  def challenge_signup_email(%OfferChallenge{} = challenge, %User{} = user, template_id) do
    start_date = Timex.to_datetime(challenge.offer.start_date, "Asia/Hong_Kong")
    end_date = Timex.to_datetime(challenge.offer.end_date, "Asia/Hong_Kong")

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-ChallengeLink-", challenge_url(challenge))
    |> Email.add_substitution(
      "-StartDate-",
      Timex.format!(start_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution(
      "-EndDate-",
      Timex.format!(end_date, "%Y-%m-%d", :strftime)
    )
    |> Email.add_substitution("-ChallengeName-", challenge.offer.name)
    |> Email.add_substitution("-Duration-", "#{get_offer_duration(challenge)} days")
    |> Email.add_substitution("-Distance-", "#{challenge.distance_target} Km")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_team_activity_completed_email(
        %OfferChallenge{} = challenge,
        %ActivityAccumulator{} = activity,
        %User{} = user
      ) do
    template_id = "d19178ae-5d36-4405-a5d7-d5862478356d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if not is_nil(sendgrid_email) and sendgrid_email != nil &&
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> team_activity_completed_email(activity, user, template_id)
      |> Mailer.send()
    end
  end

  def team_activity_completed_email(
        %OfferChallenge{} = challenge,
        %ActivityAccumulator{} = activity,
        user,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-activityDistance-", "#{Decimal.round(activity.distance)} Km")
    |> Email.add_substitution("-completedChallengeDistance-", "#{challenge.distance_covered} Km")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-timeRemaining-", "#{remaining_time(challenge)}")
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_activity_completed_email(
        %OfferChallenge{} = challenge,
        %ActivityAccumulator{} = activity
      ) do
    template_id = "3364ef25-3318-4958-a3c3-4cb97f85dc7d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if sendgrid_email != nil &&
         user_subscribed_in_category?(
           challenge.user.subscribed_email_categories,
           sendgrid_email.category.id
         ) do
      challenge
      |> activity_completed_email(activity, template_id)
      |> Mailer.send()
    end
  end

  def activity_completed_email(
        %OfferChallenge{} = challenge,
        %ActivityAccumulator{} = activity,
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-completedChallengeDistance-",
      "#{Decimal.round(challenge.distance_covered, 2)} Km"
    )
    |> Email.add_substitution("-activityDistance-", "#{Decimal.round(activity.distance, 2)} Km")
    |> Email.add_substitution(
      "-challengeDistance-",
      "#{Decimal.round(challenge.distance_target, 2)} Km"
    )
    |> Email.add_substitution("-timeRemaining-", "#{remaining_time(challenge)}")
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_challenge_failed_email(%OfferChallenge{} = challenge) do
    template_id = "52c97f2f-7c27-43eb-a9cf-655603eeb7cf"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, user: [:subscribed_email_categories])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> challenge_failed_email(template_id)
      |> Mailer.send()
    end
  end

  def challenge_failed_email(%OfferChallenge{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

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

  defp team_member_invite_link(challenge, token) do
    Routes.page_url(Endpoint, :login, %{
      team_invitation:
        Routes.offer_offer_challenge_offer_challenge_path(
          Endpoint,
          :add_team_member,
          challenge.offer.slug,
          challenge.slug,
          token
        )
    })
  end

  defp remaining_time(%OfferChallenge{end_date: end_date}) do
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

  defp challenge_duration(%OfferChallenge{start_date: start_date, end_date: end_date}),
    do: "#{Timex.diff(end_date, start_date, :days)} days"

  defp challenge_duration(_), do: ""

  defp get_offer_duration(%OfferChallenge{start_date: start_date, end_date: end_date}),
    do: Timex.diff(end_date, start_date, :days)

  defp challenge_url(challenge) do
    Routes.offer_offer_challenge_url(Endpoint, :show, challenge.offer.slug, challenge.slug)
  end

  defp new_challenge_url(challenge) do
    Routes.offer_offer_challenge_url(Endpoint, :new, challenge.offer.slug)
  end

  defp challenge_qr_code_url(challenge, offer_redeem) do
    Routes.offer_offer_challenge_offer_challenge_url(
      Endpoint,
      :send_qr_code,
      challenge.offer.slug,
      challenge.slug,
      offer_redeem.token
    )
  end

  defp add_cc(email, %OfferVendor{cc: cc_list}) when not is_nil(cc_list) do
    cleaned_cc_list =
      String.split(cc_list, ",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(String.length(&1) == 0))
      |> Enum.map(&%{email: &1})

    %{email | cc: cleaned_cc_list}
  end

  defp add_cc(email, _), do: email
end
