defmodule OmegaBraveraWeb.AdminPanelNGOView do
  use OmegaBraveraWeb, :view

  def render_fees(%Decimal{} = amount, opt) do
    bravera = Decimal.mult(Decimal.new(0.06), amount)
    gateway_percent = Decimal.mult(Decimal.new(0.034), amount)
    gateway_base_fee = Decimal.new(2.35)

    net_donation =
      Decimal.sub(amount, gateway_base_fee)
      |> Decimal.sub(gateway_percent)
      |> Decimal.sub(bravera)

    %{
      "net_donation" => net_donation,
      "bravera" => bravera,
      "gateway_fee" => Decimal.add(gateway_percent, gateway_base_fee)
    } |> Map.get(opt)
  end

  def render_kickstarter(nil), do: ""
  def render_kickstarter(milestone) when milestone > 0, do: milestone
  def render_kickstarter(milestone) when milestone == 0, do: "Kickstarter"
end
