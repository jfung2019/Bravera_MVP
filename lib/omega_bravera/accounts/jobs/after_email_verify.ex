defmodule OmegaBravera.Accounts.Jobs.AfterEmailVerify do
  use Oban.Worker, queue: :email, max_attempts: 4
  alias OmegaBravera.Accounts
  require Logger

  @impl Oban.Worker
  def perform(%{"user_id" => user_id}, _job) do
    user = Accounts.get_user!(user_id)
    OmegaBravera.Accounts.Notifier.email_three_day_welcome(user)
    :ok
  end

  def perform(args, _job) do
    Logger.error("#{__MODULE__} not recognizing args: #{inspect(args)}")
    :error
  end
end