defmodule OmegaBraveraWeb.ViewHelpersTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.ViewHelpers

  test "can render naivedatetime correctly" do
    naive_date_time = ~N[2018-09-29 05:57:32.201997]
    assert ViewHelpers.render_datetime(naive_date_time) == "29/9/18 13:57"
  end

  test "can render date from datetime" do
    {:ok, date_time, _utc_offset} = DateTime.from_iso8601("2018-10-11T03:01:37.803379Z")
    assert Phoenix.HTML.safe_to_string(ViewHelpers.render_date(date_time)) == "<span data-render-date=\"2018-10-11T03:01:37.803379Z\">"
  end

  test "tuple renders span tag with data attribute to be parsed properly" do
    assert Phoenix.HTML.safe_to_string(ViewHelpers.render_date({{2000, 1, 1}, {13, 30, 15}})) == "<span data-render-date=\"2000-01-01T13:30:15Z\">"
  end

  test "can render countdown span with datetime" do
    {:ok, date_time, _utc_offset} = DateTime.from_iso8601("2018-10-11T03:01:37.803379Z")
    assert Phoenix.HTML.safe_to_string(ViewHelpers.render_countdown_date(date_time)) == "<span data-render-countdown=\"2018-10-11T03:01:37.803379Z\">"
  end

  test "renders blank countdown with nil" do
    assert Phoenix.HTML.safe_to_string(ViewHelpers.render_countdown_date(nil)) == ""
  end

  test "renders countdown span with tuple" do
    assert Phoenix.HTML.safe_to_string(ViewHelpers.render_countdown_date({{2000, 1, 1}, {13, 30, 15}})) == "<span data-render-countdown=\"2000-01-01T13:30:15Z\">"
  end

  describe "currency_to_symbol/1" do
    test "as USD returns $" do
      assert ViewHelpers.currency_to_symbol("usd") == "$"
    end

    test "as MYR returns RM" do
      assert ViewHelpers.currency_to_symbol("myr") == "RM"
    end

    test "as HKD returns HK$" do
      assert ViewHelpers.currency_to_symbol("hkd") == "HK$"
    end

    test "as krw returns ₩" do
      assert ViewHelpers.currency_to_symbol("krw") == "₩"
    end

    test "as sgd returns ₩" do
      assert ViewHelpers.currency_to_symbol("sgd") == "S$"
    end

    test "as gbp returns ₩" do
      assert ViewHelpers.currency_to_symbol("gbp") == "£"
    end
  end
end
