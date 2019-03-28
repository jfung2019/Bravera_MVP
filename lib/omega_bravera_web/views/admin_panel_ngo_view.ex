defmodule OmegaBraveraWeb.AdminPanelNGOView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Money.Donation}

  def render_fees(%Donation{} = donation, opt) do
    amount =
      if donation.donor_pays_fees do
        donation.amount
        |> Decimal.mult(donation.exchange_rate)
      else
        donation.charged_amount
      end

    bravera = Decimal.mult(Decimal.from_float(0.06), amount)
    gateway_percent = Decimal.mult(Decimal.from_float(0.034), amount)
    gateway_base_fee = Decimal.from_float(2.35)

    net_donation =
      Decimal.sub(donation.charged_amount, gateway_base_fee)
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
      Date: <%= b.(:year, [prompt: "", options: 2019..2021]) %> / <%= b.(:month, [prompt: ""]) %> / <%= b.(:day, [prompt: ""]) %>
      Time: <%= b.(:hour, [prompt: ""]) %> : <%= b.(:minute, [prompt: ""]) %>
      """
    end

    datetime_select(form, field, [builder: builder] ++ opts)
  end
end
