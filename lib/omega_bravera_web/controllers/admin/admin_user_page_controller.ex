defmodule OmegaBraveraWeb.AdminUserPageController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Accounts, Challenges, Money, Groups, Offers}

  def index(conn, _) do
#    Accounts.admin_dashboard() |> IO.inspect()

    render(conn, "index.html",
      users: Accounts.amount_of_current_users(),
      new_users: Accounts.new_user_this_month(),
      referrals: Accounts.total_friend_referrals(),
      this_month_referrals: Accounts.friend_referrals_this_month(),
      total_distance: Accounts.total_distance(),
      weekly_distance: Accounts.total_distance_this_week(),
      male_users: Accounts.amount_of_male_users(),
      female_users: Accounts.amount_of_female_users(),
      other_users: Accounts.amount_of_other_users(),
      ios_users: Accounts.amount_of_ios_users(),
      android_users: Accounts.amount_of_android_users(),
      groups: Groups.total_groups(),
      offers: Offers.total_offers(),
      online_offers: Offers.total_online_offers(),
      in_store_offers: Offers.total_in_store_offers(),
      unlocked_rewards: Accounts.total_rewards_unlocked(),
      claimed_rewards: Accounts.total_rewards_claimed(),
      donors: Money.amount_of_donors(),
      activities: Challenges.amount_of_activities(),
      distance_target: Challenges.total_distance_target(),
      challenge_days: Challenges.get_total_challenge_days(),
      donations: Money.count_of_donations(),
      total_secured: Money.total_secured_donations()
    )
  end
end
