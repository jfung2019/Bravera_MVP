defmodule OmegaBravera.Accounts.Jobs.PartnerUserVerified do
  use Oban.Worker, queue: :email, max_attempts: 1

  alias OmegaBravera.Accounts.{Notifier, SlackNotifier}

  @env Application.get_env(:omega_bravera, :env)

  @impl Oban.Worker
  def perform(%{"id" => partner_user_id}, _job) do
    partner_user =
      OmegaBravera.Accounts.get_partner_user(partner_user_id, [:location, :organizations])

    Notifier.notify_verified_partner_user(partner_user)
    Notifier.notify_bravera_verified_partner_user(partner_user)

    if @env != :test do
      SlackNotifier.notify_new_partner_user(partner_user)
    end

    :ok
  end
end
