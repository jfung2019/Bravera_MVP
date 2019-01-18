defmodule OmegaBraveraWeb.AdminUserPageController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Accounts, Challenges, Money}

  def index(conn, _) do
    render(conn, "index.html",
      users: Accounts.amount_of_current_users(),
      donors: Money.amount_of_donors(),
      activities: Challenges.amount_of_activities(),
      distance_target: Challenges.total_distance_target(),
      challenge_days: Challenges.get_total_challenge_days(),
      donations: Money.count_of_donations(),
      total_secured: Money.total_secured_donations()
    )
  end
end
