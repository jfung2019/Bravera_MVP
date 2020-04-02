defmodule OmegaBravera.Accounts.Jobs.WeeklySummary do
  use Oban.Worker, queue: :email, max_attempts: 4

  def perform(_args, _job) do
    OmegaBravera.Accounts.get_all_user_ids()
    |> Enum.each(fn id ->
      OmegaBravera.Accounts.Jobs.WeeklySummaryForUser.new(%{"user_id" => id})
      |> Oban.insert()
    end)

    :ok
  end
end
