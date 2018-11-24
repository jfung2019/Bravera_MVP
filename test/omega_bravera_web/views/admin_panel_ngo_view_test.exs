defmodule OmegaBraveraWeb.AdminPanelNGOViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.AdminPanelNGOView

  describe "render_fees/2" do
    test "returns correct bravera fees" do
      assert Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "bravera"), Decimal.new(3.00))
      refute Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "bravera"), Decimal.new(1.00))
    end

    test "returns correct net donation" do
      assert Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "net_donation"), Decimal.new(42.950))
      refute Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "net_donation"), Decimal.new(1.00))
    end

    test "returns gateway fees" do
      assert Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "gateway_fee"), Decimal.new(4.050))
      refute Decimal.equal?(AdminPanelNGOView.render_fees(Decimal.new(50), "gateway_fee"), Decimal.new(1.00))
    end
  end
end
