defmodule OmegaBravera.Accounts.ThreeDayWelcome do
  alias OmegaBravera.Accounts

  def process_welcome do
    Accounts.get_users_from_three_days_ago()
    |> Enum.each(&Accounts.Notifier.email_three_day_welcome/1)
  end
end
