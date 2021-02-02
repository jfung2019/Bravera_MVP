defmodule OmegaBravera.Accounts.Notifier do
  alias OmegaBravera.{
    Repo,
    Notifications,
    Accounts.User,
    Accounts.Credential,
    Accounts.PartnerUser,
    Groups.GroupApproval,
    Groups.Partner,
    Offers.Offer,
    Offers.OfferApproval
  }

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint
  alias SendGrid.{Mail, Email}
  import OmegaBravera.Notifications, only: [user_subscribed_in_category?: 2]

  def send_bonus_added_to_inviter_email(%User{} = user) do
    template_id = "bc8d21c3-7d6c-47c4-87c3-191c1cbc772d"

    user
    |> bonus_added_to_inviter_email(template_id)
    |> Mail.send()
  end

  def bonus_added_to_inviter_email(
        %User{email: user_email, total_points: total_points},
        template_id
      ) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-newPointsBalance-", Decimal.to_string(total_points))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user_email)
  end

  def send_user_signup_email(%User{} = user, redirect_to \\ "/") do
    template_id = "b47d2224-792a-43d8-b4b2-f53b033d2f41"
    sendgrid_email = Notifications.get_sendgrid_email_by_sendgrid_id(template_id)
    user = Repo.preload(user, [:subscribed_email_categories])

    if user_subscribed_in_category?(user.subscribed_email_categories, sendgrid_email.category.id) do
      user
      |> user_signup_email(redirect_to, template_id)
      |> Mail.send()
    end
  end

  def user_signup_email(%User{} = user, redirect_to, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-firstName-", User.full_name(user))
    |> Email.add_substitution(
      "-emailVerificationUrl-",
      Routes.user_url(Endpoint, :activate_email, user.email_activation_token, %{
        redirect_to: redirect_to
      })
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  def send_app_password_reset_email(%Credential{} = credential) do
    template_id = "ab8b34b3-7d10-40be-b732-e375cc14a8ab"
    sendgrid_email = Notifications.get_sendgrid_email_by_sendgrid_id(template_id)
    credential = Repo.preload(credential, user: [:subscribed_email_categories])

    if user_subscribed_in_category?(
         credential.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      credential
      |> app_password_reset_email(template_id)
      |> Mail.send()
    end
  end

  def app_password_reset_email(%Credential{} = credential, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution("-ResetCode-", credential.reset_token)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(credential.user.email)
  end

  def send_password_reset_email(%Credential{} = credential) do
    template_id = "1bfb8b3b-e5fd-4052-baad-55fd4a5f7c2b"
    sendgrid_email = Notifications.get_sendgrid_email_by_sendgrid_id(template_id)
    credential = Repo.preload(credential, user: [:subscribed_email_categories])

    if user_subscribed_in_category?(
         credential.user.subscribed_email_categories,
         sendgrid_email.category.id
       ) do
      credential
      |> password_reset_email(template_id)
      |> Mail.send()
    end
  end

  def send_password_reset_email(%PartnerUser{email: email, username: username, first_name: first_name, reset_token: reset_token}) do
    template_id = "6ad5a528-9f86-4301-8ff3-86db415a860d"

    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution(
      "-ResetLink-",
      Routes.partner_user_password_url(Endpoint, :edit, reset_token)
    )
    |> Email.add_substitution("-UserName-", username)
    |> Email.add_substitution("-FirstName-", first_name)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
    |> Mail.send()
  end

  def password_reset_email(%Credential{} = credential, template_id) do
    Email.build()
    |> Email.put_template(template_id)
    |> Email.add_substitution(
      "-passwordResetUrl-",
      Routes.password_url(Endpoint, :edit, credential)
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(credential.user.email)
  end

  def email_three_day_welcome(user) do
    Email.build()
    |> Email.put_template("a6f88b25-4d6d-4d0f-9314-4c7c3c72e2e6")
    |> Email.add_substitution("-firstName-", user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
    |> Mail.send()
  end

  def no_activity_after_signup(user) do
    Email.build()
    |> Email.put_template("029cdf2b-13bf-4671-8b98-062cfe4de891")
    |> Email.add_substitution("-firstName-", user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
    |> Mail.send()
  end

  def no_activity_after_one_week(user) do
    Email.build()
    |> Email.put_template("ff39a8ed-9335-45a5-8369-59e72eb40038")
    |> Email.add_substitution("-firstName-", user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
    |> Mail.send()
  end

  def weekly_summary(
        user,
        total_points,
        last_week_total_points,
        completed_challenges,
        rewards_redeemed,
        friend_referrals,
        daily_goal_reached
      ) do
    Email.build()
    |> Email.put_template("a09d7fb8-cd4d-4b9c-9dc1-bb8bed829fff")
    |> Email.add_substitution("-firstName-", user.firstname)
    # Need to convert numbers to string
    |> Email.add_substitution("-totalPoints-", "#{total_points}")
    |> Email.add_substitution("-lastWeekTotal-", "#{last_week_total_points}")
    |> Email.add_substitution("-challengesCompleted-", "#{completed_challenges}")
    |> Email.add_substitution("-rewardsRedeemed-", "#{rewards_redeemed}")
    |> Email.add_substitution("-friendReferralCount-", "#{friend_referrals}")
    |> Email.add_substitution("-daysHitLimit-", "#{daily_goal_reached}")
    |> Email.add_substitution("-dailyLimit-", "#{user.daily_points_limit}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(user.email)
    |> Mail.send()
  end

  def partner_user_signup_email(%PartnerUser{} = partner_user) do
    Email.build()
    |> Email.put_template("b47d2224-792a-43d8-b4b2-f53b033d2f41")
    |> Email.add_substitution("-firstName-", partner_user.email)
    |> Email.add_substitution(
      "-emailVerificationUrl-",
      Routes.partner_user_session_url(
        Endpoint,
        :activate_email,
        partner_user.email_activation_token
      )
    )
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(partner_user.email)
    |> Mail.send()
  end

  def customer_group_modified_email(%PartnerUser{} = partner_user, %Partner{} = partner) do
    Email.build()
    |> Email.put_template("dc0b20c4-1208-4c6a-845a-9dee4e7ff48a")
    |> Email.add_substitution("-AccountUsername-", partner_user.username)
    |> Email.add_substitution("-EmailAddress-", partner_user.email)
    |> Email.add_substitution(
      "-GroupEditLink-",
      Routes.admin_panel_group_approval_url(Endpoint, :show, partner)
    )
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to("support@bravera.co")
    |> Mail.send()
  end

  def customer_offer_modified_email(%PartnerUser{} = partner_user, %Offer{} = offer) do
    Email.build()
    |> Email.put_template("d8fadde1-2ad8-4274-8ee1-6f48a2820da1")
    |> Email.add_substitution("-AccountUsername-", partner_user.username)
    |> Email.add_substitution("-EmailAddress-", partner_user.email)
    |> Email.add_substitution(
      "-OfferEditLink-",
      Routes.admin_panel_offer_approval_url(Endpoint, :show, offer)
    )
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to("support@bravera.co")
    |> Mail.send()
  end

  def notify_customer_group_email(
        %PartnerUser{username: username, email: email},
        %Partner{name: group_name},
        %GroupApproval{status: :approved}
      ) do
    Email.build()
    |> Email.put_template("af72c512-278e-49b9-b2d5-3cb9ee4eb7f6")
    |> Email.add_substitution("-username-", username)
    |> Email.add_substitution("-GroupName-", group_name)
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("support@bravera.co")
    |> Email.add_to(email)
    |> Mail.send()
  end

  def notify_customer_group_email(
        %PartnerUser{email: email, username: username},
        %Partner{name: group_name},
        %GroupApproval{status: :denied, message: message}
      ) do
    Email.build()
    |> Email.put_template("6d8fc814-3e9a-473a-bed8-687381320bd9")
    |> Email.add_substitution("-username-", username)
    |> Email.add_substitution("-GroupName-", group_name)
    |> Email.add_substitution("-Message-", message)
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("support@bravera.co")
    |> Email.add_to(email)
    |> Mail.send()
  end

  def notify_customer_offer_email(
        %PartnerUser{username: username, email: email},
        %OfferApproval{status: :approved},
        %Offer{name: name}
      ) do
    Email.build()
    |> Email.put_template("2516ad29-1350-4353-a8db-9f72bf240e01")
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("support@bravera.co")
    |> Email.add_substitution("-username-", username)
    |> Email.add_substitution("-OfferName-", name)
    |> Email.add_to(email)
    |> Mail.send()
  end

  def notify_customer_offer_email(
        %PartnerUser{email: email, username: username},
        %OfferApproval{status: :denied, message: message},
        %Offer{name: name}
      ) do
    Email.build()
    |> Email.put_template("6ea1749a-6d02-499d-aabd-ec9dae873aa4")
    |> Email.add_substitution("-message-", message)
    |> Email.add_substitution("-username-", username)
    |> Email.add_substitution("-OfferName-", name)
    |> Email.put_from("support@bravera.co", "Bravera")
    |> Email.add_bcc("support@bravera.co")
    |> Email.add_to(email)
    |> Mail.send()
  end
end
