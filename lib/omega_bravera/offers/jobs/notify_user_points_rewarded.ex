defmodule OmegaBravera.Offers.Jobs.NotifyUserPointsRewarded do
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.{Accounts, Offers, Offers.Notifier}

  @impl Oban.Worker
  def perform(%{"redeem_id" => redeem_id}, _job) do
    offer_redeem = Offers.get_offer_redeems!(redeem_id, [offer_challenge: [:user]])
    user_with_points = Accounts.get_user_with_points(offer_redeem.user_id)

    Offers.Notifier.send_user_reward_redemption_successful(offer_redeem.offer_challenge, user_with_points)
    :ok
  end
end