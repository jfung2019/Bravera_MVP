defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    {:ok, Offers.list_offers_for_user(user_id)}
  end

  # search all location with pagination
  def search_offers_paginated(
        _root,
        %{keyword: keyword, location_id: -1, coordinate: nil} = args,
        %{
          context: %{current_user: %{id: user_id}}
        }
      ),
      do: Offers.search_offers_for_user_paginated(keyword, nil, nil, user_id, args)

  # use user's location to search with pagination
  def search_offers_paginated(
        _root,
        %{keyword: keyword, location_id: nil, coordinate: coordinate} = args,
        %{
          context: %{current_user: %{id: user_id, location_id: location_id}}
        }
      ),
      do: Offers.search_offers_for_user_paginated(keyword, location_id, coordinate, user_id, args)

  # search offers with pagination
  def search_offers_paginated(
        _root,
        %{keyword: keyword, location_id: location_id, coordinate: coordinate} = args,
        %{
          context: %{current_user: %{id: user_id}}
        }
      ),
      do: Offers.search_offers_for_user_paginated(keyword, location_id, coordinate, user_id, args)

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

  def list_offer_coordinates(_root, %{coordinate: %{longitude: long, latitude: lat}}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    {:ok,
     %{
       offer_coordinates: Offers.list_offer_coordinates(user_id, long, lat),
       loaded_longitude: Decimal.from_float(long),
       loaded_latitude: Decimal.from_float(lat)
     }}
  end

  def list_offer_coordinates(_root, %{coordinate: nil}, %{
        context: %{current_user: %{id: user_id, location_id: location_id}}
      }) do
    %{geom: %{coordinates: {long, lat}}} = OmegaBravera.Locations.get_location!(location_id)

    {:ok,
     %{
       offer_coordinates: Offers.list_offer_coordinates(user_id, long, lat),
       loaded_longitude: Decimal.from_float(long),
       loaded_latitude: Decimal.from_float(lat)
     }}
  end
end
