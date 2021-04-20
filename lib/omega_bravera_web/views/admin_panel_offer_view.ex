defmodule OmegaBraveraWeb.AdminPanelOfferView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.Offers.OfferChallenge

  def completed_challenges(offer_challenges) do
    stats =
      Enum.reduce(offer_challenges, %{active: 0, complete: 0, expired: 0}, fn offer_challenge,
                                                                              acc ->
        case offer_challenge.status do
          "active" -> Map.update(acc, :active, 0, &(&1 + 1))
          "expired" -> Map.update(acc, :expired, 0, &(&1 + 1))
          "complete" -> Map.update(acc, :complete, 0, &(&1 + 1))
          _ -> acc
        end
      end)

    "Finished: #{stats[:complete]} <br /> Expired: #{stats[:expired]} <br /> Live: #{
      stats[:active]
    }"
  end

  def get_total_redeems_value(offer_redeems) do
    Enum.filter(offer_redeems, fn offer_redeem ->
      not is_nil(offer_redeem.offer_reward_id) and offer_redeem.status == "redeemed"
    end)
    |> Enum.reduce(0, &((&1.offer_reward.value || 0) + &2))
  end

  def redeems_total(redeems) when is_list(redeems) and length(redeems) > 0 do
    Enum.reduce(redeems, 0, fn redeem, acc ->
      if redeem.status == "redeemed" do
        acc + 1
      else
        acc
      end
    end)
  end

  def redeems_total(_), do: 0

  def render_redeemed_reward_name(%OfferChallenge{has_team: false, offer_redeems: offer_redeems}) do
    case Enum.find(offer_redeems, nil, &(&1.status == "redeemed")) do
      %{offer_reward: offer_reward} -> offer_reward.name
      nil -> ""
    end
  end

  def render_redeemed_reward_name(%OfferChallenge{has_team: true}), do: ""
end
