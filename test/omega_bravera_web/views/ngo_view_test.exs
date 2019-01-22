defmodule OmegaBraveraWeb.NGOViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBraveraWeb.NGOView
  alias OmegaBravera.Fundraisers.NGO

  test "team_enabled_ngo/1 when additional members is 0 or less returns false" do
    refute NGOView.team_enabled_ngo?(%NGO{additional_members: 0})
    refute NGOView.team_enabled_ngo?(%NGO{additional_members: -1})
  end

  test "team_enabled_ngo/1 when additional members is more than 0 true" do
    assert NGOView.team_enabled_ngo?(%NGO{additional_members: 3})
  end
end
