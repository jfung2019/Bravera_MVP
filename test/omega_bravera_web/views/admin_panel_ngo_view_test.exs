defmodule OmegaBraveraWeb.AdminPanelNGOViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.AdminPanelNGOView

  describe "render_fees/2" do
    test "returns correct bravera fees" do
      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(Decimal.new(50), Decimal.new(1), "hkd", "bravera"),
               Decimal.new(3.00)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(Decimal.new(50), Decimal.new(1), "hkd", "bravera"),
               Decimal.new(1.00)
             )
    end

    test "returns correct net donation" do
      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 Decimal.new(50),
                 Decimal.new(1),
                 "hkd",
                 "net_donation"
               ),
               Decimal.new(43)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 Decimal.new(50),
                 Decimal.new(1),
                 "hkd",
                 "net_donation"
               ),
               Decimal.new(1.00)
             )
    end

    test "returns gateway fees" do
      assert Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 Decimal.new(50),
                 Decimal.new(1),
                 "hkd",
                 "gateway_fee"
               ),
               Decimal.new(4.1)
             )

      refute Decimal.equal?(
               AdminPanelNGOView.render_fees(
                 Decimal.new(50),
                 Decimal.new(1),
                 "hkd",
                 "gateway_fee"
               ),
               Decimal.new(1.00)
             )
    end
  end
end
