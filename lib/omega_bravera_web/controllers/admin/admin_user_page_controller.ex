defmodule OmegaBraveraWeb.AdminUserPageController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Accounts, Challenges, Money, Groups, Offers}

  def index(conn, _) do
    render(conn, "index.html",
      users_info: Accounts.admin_dashboard_users_info(),
      groups_info: Groups.admin_dashboard_groups_info(),
      offers_info: Offers.admin_dashboard_offers_info(),
      unlocked_rewards: Accounts.total_rewards_unlocked(),
      claimed_rewards: Accounts.total_rewards_claimed(),
      donors: Money.amount_of_donors(),
      activities: Challenges.amount_of_activities(),
      donations: Money.count_of_donations(),
      total_secured: Money.total_secured_donations()
    )
  end
end
