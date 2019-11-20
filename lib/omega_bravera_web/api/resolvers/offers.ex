defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case OmegaBravera.Accounts.get_user_strava(user_id) do
      nil ->
        {:ok, Offers.api_list_offers()}

      _ ->
        {:ok, Offers.api_list_offers_with_segments()}
    end
  end

  def offer_offer_challenges(_root, %{offer_id: offer_id}, _info),
    do: {:ok, Offers.list_offer_offer_challenges(offer_id)}

  def get_offer(_root, %{id: offer_id}, %{context: %{current_user: _current_user}}),
    do: {:ok, Offers.get_offer!(offer_id)}

  def get_offer(_root, _args, _info), do: {:error, "not_authorized"}
end
