defmodule OmegaBraveraWeb.Api.Resolvers.OfferRedeems do
  alias OmegaBravera.{Offers, Points}
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def latest_expired_redeems(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Offers.list_expired_offer_redeems(user_id)}

  def claim_online_offer_reward(_root, %{offer_challenge_slug: offer_challenge_slug}, %{context: %{current_user: %{id: user_id}}}) do
    with %{} = offer_redeem <- Offers.get_offer_redeem_by_slug_user_id(offer_challenge_slug, user_id),
         {:ok, redeem} <- Offers.update_offer_redeems(offer_redeem, %{status: "redeemed"}),
         {:ok, point} <- Points.create_bonus_points(%{user_id: user_id, source: :redeem, value: 1}) do
      {:ok, redeem}
    else
      nil ->
        {:error, message: "Failed to find offer redeem"}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Failed to redeem offer", details: Helpers.transform_errors(changeset)}

      _ ->
        {:error, message: "Failed to redeem offer"}
    end
  end
end
