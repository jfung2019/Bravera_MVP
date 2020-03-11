defmodule OmegaBravera.Accounts.Jobs.NoActivityAfterSignup do
  use Oban.Worker, queue: :email, max_attempts: 4
  alias OmegaBravera.{Accounts, Devices}
  require Logger

  @impl Oban.Worker
  def perform(%{"user_id" => user_id}, _job) do
    case Devices.get_active_device_by_user_id(user_id) do
      nil ->
        user_id
        |> Accounts.get_user!()
        |> OmegaBravera.Accounts.Notifier.no_activity_after_signup()

      _ ->
        :ok
    end
  end

  def perform(args, _job) do
    Logger.error("#{__MODULE__} not recognizing args: #{inspect(args)}")
    :error
  end
end
