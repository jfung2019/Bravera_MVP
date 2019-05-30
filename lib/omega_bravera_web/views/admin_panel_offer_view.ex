defmodule OmegaBraveraWeb.AdminPanelOfferView do
  use OmegaBraveraWeb, :view

  def registration_date_builder(form, field, opts \\ []) do
    builder = fn b ->
      ~e"""
      Date: <%= b.(:year, [prompt: "", options: 2019..2021]) %> / <%= b.(:month, [prompt: ""]) %> / <%= b.(:day, [prompt: ""]) %>
      Time: <%= b.(:hour, [prompt: ""]) %> : <%= b.(:minute, [prompt: ""]) %>
      """
    end

    datetime_select(form, field, [builder: builder] ++ opts)
  end

  def completed_challenges(offer_challenges) do
    stats =
      Enum.reduce(offer_challenges, %{active: 0, complete: 0, expired: 0}, fn offer_challenge, acc ->
        cond do
          offer_challenge.status == "active" -> Map.update(acc, :active, 0, &(&1 + 1))
          offer_challenge.status == "expired" -> Map.update(acc, :expired, 0, &(&1 + 1))
          offer_challenge.status == "complete" -> Map.update(acc, :complete, 0, &(&1 + 1))
          true -> acc
        end
      end)

    "C: #{stats[:complete]} <br /> E: #{stats[:expired]} <br /> L: #{stats[:active]}"
  end

  def get_total_redeems_value(offer_redeems) do
    Enum.filter(offer_redeems, fn offer_redeem ->
      not is_nil(offer_redeem.offer_reward_id) and offer_redeem.status == "redeemed"
    end)
    |> Enum.reduce(0, &(&1.offer_reward.value + &2))
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
end
