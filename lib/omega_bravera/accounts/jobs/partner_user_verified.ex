defmodule OmegaBravera.Accounts.Jobs.PartnerUserVerified do
  use Oban.Worker, queue: :email, max_attempts: 1

  alias OmegaBravera.Accounts.Notifier

  @impl Oban.Worker
  def perform(%{"id" => partner_user_id}, _job) do
    partner_user =
      OmegaBravera.Accounts.get_partner_user(partner_user_id, [:location, :organizations])

    Notifier.notify_verified_partner_user(partner_user)
    Notifier.notify_bravera_verified_partner_user(partner_user)

    :ok
  end
end
