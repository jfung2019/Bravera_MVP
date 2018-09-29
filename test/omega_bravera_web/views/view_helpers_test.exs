defmodule OmegaBraveraWeb.ViewHelpersTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.ViewHelpers

  test "can render naivedatetime correctly" do
    naive_date_time = ~N[2018-09-29 05:57:32.201997]
    assert ViewHelpers.render_datetime(naive_date_time) == "29/9/18 13:57"
  end
end