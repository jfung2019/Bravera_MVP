defmodule OmegaBravera.Offers.Notifier do
  alias OmegaBravera.{
    Offers.OfferChallenge,
    Offers.OfferChallengeActivity,
    Repo,
    Emails
  }

  alias SendGrid.{Email, Mailer}

  def send_reward_completion_email(%OfferChallenge{} = challenge) do
    template_id = "42873800-965d-4e0d-bcea-4c59a1934d80"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> Repo.preload(:offer)
      |> reward_completion_email(template_id)
      |> Mailer.send()
    end
  end

  def reward_completion_email(%OfferChallenge{} = challenge, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeLink-", challenge_url(challenge))
    |> Email.add_substitution("qrCode", challenge_qr_code_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_pre_registration_challenge_sign_up_email(%OfferChallenge{} = challenge, path) do
    template_id = "75c0cbaa-5f00-410f-b0cc-4167c895d381"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> pre_registration_challenge_signup_email(path, template_id)
      |> Mailer.send()
    end
  end

  def pre_registration_challenge_signup_email(%OfferChallenge{} = challenge, path, template_id) do
    start_date = Timex.to_datetime(challenge.offer.start_date, "Asia/Hong_Kong")
    end_date = Timex.to_datetime(challenge.offer.end_date, "Asia/Hong_Kong")

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-ChallengeLink-",
      "#{Application.get_env(:omega_bravera, :app_base_url)}#{path}"
    )
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

  def send_challenge_signup_email(%OfferChallenge{} = challenge, path) do
    template_id = "34c53203-5dd3-4de3-8ae9-4a6abd52be9d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
         challenge.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      challenge
      |> challenge_signup_email(path, template_id)
      |> Mailer.send()
    end
  end

  def challenge_signup_email(%OfferChallenge{} = challenge, path, template_id) do
    start_date = Timex.to_datetime(challenge.offer.start_date, "Asia/Hong_Kong")
    end_date = Timex.to_datetime(challenge.offer.end_date, "Asia/Hong_Kong")

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution(
      "-ChallengeLink-",
      "#{Application.get_env(:omega_bravera, :app_base_url)}#{path}"
    )
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

  def send_activity_completed_email(
        %OfferChallenge{} = challenge,
        %OfferChallengeActivity{} = activity
      ) do
    template_id = "3364ef25-3318-4958-a3c3-4cb97f85dc7d"
    sendgrid_email = Emails.get_sendgrid_email_by_sendgrid_id(template_id)
    challenge = Repo.preload(challenge, [:offer, user: [:subscribed_email_categories]])

    if user_subscribed_in_category?(
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
        %OfferChallengeActivity{} = activity,
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

  defp get_offer_duration(%OfferChallenge{start_date: start_date, end_date: end_date}),
    do: Timex.diff(end_date, start_date, :days)

  defp challenge_url(challenge) do
    "#{Application.get_env(:omega_bravera, :app_base_url)}/#{challenge.offer.slug}/#{
      challenge.slug
    }"
  end

  defp challenge_qr_code_url(challenge) do
    "#{challenge_url(challenge)}/challenge.redeem_token"
  end
end
