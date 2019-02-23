defmodule OmegaBraveraWeb.AdminPanelNGOViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBraveraWeb.AdminPanelNGOView

  describe "render_fees/2" do
    test "returns correct bravera fees" do
      donation = insert(:donation)

      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(donation, "bravera"),
               Decimal.new(9)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(donation, "bravera"),
               Decimal.new(1)
             )
    end

    test "returns correct net donation" do
      donation = insert(:donation)

      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 donation,
                 "net_donation"
               ),
               Decimal.from_float(133.6)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 donation,
                 "net_donation"
               ),
               Decimal.from_float(1.00)
             )
    end

    test "returns gateway fees" do
      donation = insert(:donation)

      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 donation,
                 "gateway_fee"
               ),
               Decimal.from_float(7.5)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 donation,
                 "gateway_fee"
               ),
               Decimal.from_float(1.00)
             )
    end
  end
end
