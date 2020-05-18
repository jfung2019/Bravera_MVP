defmodule OmegaBravera.Offers.ActivityIngestionShared do
  @moduledoc """
  When digesting activities, sometimes we do the same in different places,
  so it's good to share the logic so we have less things to change.
  """
  alias OmegaBravera.{Repo, Offers}
  alias Offers.OfferRedeem
  alias OmegaBraveraWeb.Endpoint

  @doc """
  Process completed offer challenges and let the users know
  who are connected over websocket.
  """
  @spec process_completed_offer_challenge(OmegaBravera.Offers.OfferChallenge.t()) ::
          OmegaBravera.Offers.OfferChallenge.t()
  def process_completed_offer_challenge(%{status: "complete"} = updated) do
    # Notify listeners that the offer was completed
    Endpoint.broadcast("user:#{updated.user_id}", "offer_challenge_completed", %{
      challenge_id: updated.id
    })

    # if challenge was completed and offer has expiration_days
    # update the reward to the right time
    if updated.offer.redemption_days != nil do
      expired_at = Timex.now() |> Timex.shift(days: updated.offer.redemption_days)

      offer_redeem =
        Repo.get_by(OfferRedeem, offer_challenge_id: updated.id, user_id: updated.user_id)

      Offers.update_offer_redeems(offer_redeem, %{expired_at: expired_at})
    end

    updated
  end

  def process_completed_offer_challenge(updated), do: updated
end
