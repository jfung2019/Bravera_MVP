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

  def get_total_redeems_value(offer_redeems) do
    Enum.reduce(offer_redeems, 0, &(&1.offer_reward.value + &2))
  end
end
