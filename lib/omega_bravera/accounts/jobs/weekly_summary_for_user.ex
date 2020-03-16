defmodule OmegaBravera.Accounts.Jobs.WeeklySummaryForUser do
  use Oban.Worker, queue: :email, max_attempts: 4
  alias OmegaBravera.{Accounts, Offers, Points}
  require Logger

  @impl Oban.Worker
  def perform(%{"user_id" => user_id}, _job) do
    user = Accounts.get_user!(user_id)
    completed_challenges = Offers.number_of_completed_challenges_over_week(user_id)
    rewards_redeemed = Offers.number_of_rewards_redeemed_over_week(user_id)
    friend_referrals = Accounts.number_of_referrals_over_week(user_id)
    points_over_week = Points.get_user_points_one_week(user_id)
    last_week_total_points = Enum.reduce(points_over_week, Decimal.new(0), fn %{value: v}, acc -> Decimal.add(v, acc) end)

    max = Decimal.new(80)
    daily_goal_reached =
      Enum.filter(points_over_week, fn %{value: v} -> Decimal.cmp(v, max) != :lt end) |> Enum.count()

    total_points = Points.total_points(user_id)

    OmegaBravera.Accounts.Notifier.weekly_summary(
      user,
      total_points,
      last_week_total_points,
      completed_challenges,
      rewards_redeemed,
      friend_referrals,
      daily_goal_reached
    )
  end

  def perform(args, _job) do
    Logger.error("#{__MODULE__} not recognizing args: #{inspect(args)}")
    :error
  end
end
