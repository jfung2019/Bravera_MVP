defmodule OmegaBraveraWeb.AdminPanelNGOView do
  use OmegaBraveraWeb, :view

  def render_fees(%Decimal{} = amount, %Decimal{} = exchange_rate, challenge_currency, opt) do
    amount =
      if challenge_currency != "hkd" do
        Decimal.mult(exchange_rate, amount)
      else
        amount
      end

    bravera = Decimal.mult(Decimal.new(0.06), amount)
    gateway_percent = Decimal.mult(Decimal.new(0.034), amount)
    gateway_base_fee = Decimal.new(2.35)

    net_donation =
      Decimal.sub(amount, gateway_base_fee)
      |> Decimal.sub(gateway_percent)
      |> Decimal.sub(bravera)

    %{
      "net_donation" => Decimal.round(net_donation, 1),
      "bravera" => Decimal.round(bravera, 1),
      "gateway_fee" => Decimal.round(Decimal.add(gateway_percent, gateway_base_fee), 1)
    }
    |> Map.get(opt)
  end

  def render_kickstarter(nil), do: ""
  def render_kickstarter(milestone) when milestone > 0, do: milestone
  def render_kickstarter(milestone) when milestone == 0, do: "Kickstarter"

  def registration_date_builder(form, field, opts \\ []) do
    builder = fn b ->
      ~e"""
      Date: <%= b.(:year, [prompt: "", options: 2018..2021]) %> / <%= b.(:month, [prompt: ""]) %> / <%= b.(:day, [prompt: ""]) %>
      Time: <%= b.(:hour, [prompt: ""]) %> : <%= b.(:minute, [prompt: ""]) %>
      """
    end

    datetime_select(form, field, [builder: builder] ++ opts)
  end
end
