defmodule OmegaBravera.Offers.Jobs.ExpireOfferRedeem do
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.Offers

  @impl Oban.Worker
  def perform(_args, _job) do
    Offers.expire_expired_offer_redeems()
    :ok
  end
end
