defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    {:ok, Offers.list_offers_for_user(user_id)}
  end

  # search all location
  def search_offers(_root, %{keyword: keyword, location_id: -1}, %{
        context: %{current_user: %{id: user_id}}
      }),
      do: Offers.search_offers_for_user(keyword, nil, user_id)

  # use user's location to search
  def search_offers(_root, %{keyword: keyword, location_id: nil}, %{
        context: %{current_user: %{id: user_id, location_id: location_id}}
      }),
      do: Offers.search_offers_for_user(keyword, location_id, user_id)

  # search offers
  def search_offers(_root, %{keyword: keyword, location_id: location_id}, %{
        context: %{current_user: %{id: user_id}}
      }),
      do: Offers.search_offers_for_user(keyword, location_id, user_id)

  # search all location with pagination
  def search_offers_paginated(_root, %{keyword: keyword, location_id: -1} = args, %{
    context: %{current_user: %{id: user_id}}
  }),
      do: Offers.search_offers_for_user_paginated(keyword, nil, user_id, args)

  # use user's location to search with pagination
  def search_offers_paginated(_root, %{keyword: keyword, location_id: nil} = args, %{
    context: %{current_user: %{id: user_id, location_id: location_id}}
  }), do: Offers.search_offers_for_user_paginated(keyword, location_id, user_id, args)

  # search offers with pagination
  def search_offers_paginated(_root, %{keyword: keyword, location_id: location_id} = args, %{
    context: %{current_user: %{id: user_id}}
  }),
      do: Offers.search_offers_for_user_paginated(keyword, location_id, user_id, args)

  def offer_offer_challenges(_root, %{offer_id: offer_id}, _info),
    do: {:ok, Offers.list_offer_offer_challenges(offer_id)}

  def offer_offer_challenges_paginated(_root, %{offer_id: offer_id} = args, _info),
    do: Offers.offer_offer_challenges_paginated(offer_id, args)

  def get_offer(_root, %{slug: offer_slug}, _info) do
    case Offers.get_offer_by_slug(offer_slug) do
      nil ->
        {:error, message: "Offer not found"}

      offer ->
        {:ok, offer}
    end
  end
end
