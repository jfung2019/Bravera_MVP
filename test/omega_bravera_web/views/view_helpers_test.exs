defmodule OmegaBraveraWeb.ViewHelpersTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.ViewHelpers

  test "can render naivedatetime correctly" do
    naive_date_time = ~N[2018-09-29 05:57:32.201997]
    assert ViewHelpers.render_datetime(naive_date_time) == "29/9/18 13:57"
  end

  test "can render date from datetime" do
    {:ok, date_time, _utc_offset} = DateTime.from_iso8601("2018-10-11T03:01:37.803379Z")
    assert ViewHelpers.render_date(date_time) == "11/10/2018"
  end
end
