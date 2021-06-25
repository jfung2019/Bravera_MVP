defmodule OmegaBraveraWeb.Api.Resolvers.OfferRedeems do
  alias OmegaBravera.Offers
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_expired_redeems(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Offers.list_expired_offer_redeems(user_id)}

  def claim_online_offer_reward(_root, %{offer_challenge_slug: offer_challenge_slug}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    with %{} = offer_redeem <-
           Offers.get_offer_redeem_by_slug_user_id(offer_challenge_slug, user_id),
         {:ok, %{redeem: redeem}} <- Offers.confirm_online_offer_redeem(offer_redeem) do
      {:ok, redeem}
    else
      nil ->
        {:error, message: "Failed to find offer redeem"}

      {:error, _, %Ecto.Changeset{} = changeset, _} ->
        {:error, message: "Failed to redeem offer", details: Helpers.transform_errors(changeset)}

      _ ->
        {:error, message: "Failed to redeem offer"}
    end
  end
end
