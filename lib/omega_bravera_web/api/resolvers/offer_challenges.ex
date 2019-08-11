defmodule OmegaBraveraWeb.Api.Resolvers.OfferChallenges do
  require Logger

  alias OmegaBravera.{Offers, Repo}
  alias OmegaBraveraWeb.Offer.OfferChallengeHelper

  def create(_root, %{input: %{offer_slug: offer_slug}}, %{context: %{current_user: current_user}}) do

    case Offers.get_offer_by_slug(offer_slug) do
      nil ->
        {:error, "Offer not found"}

      offer ->
        create_challenge(offer, current_user)
    end
  end

  def create(_, _, %{}), do: {:error, "Action Requires Login"}

  defp create_challenge(offer, current_user) do
    case Offers.create_offer_challenge(offer, current_user) do
      {:ok, offer_challenge} ->
        OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))
        {:ok, offer_challenge}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("API: Could not sign up user for offer. Reason: #{inspect(changeset)}")
    end
  end
end
