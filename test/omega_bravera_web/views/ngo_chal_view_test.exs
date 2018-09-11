defmodule OmegaBraveraWeb.NGOChalViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBraveraWeb.NGOChalView

  test "active_challenge?/1 returns true if the challenge is active" do
    assert NGOChalView.active_challenge?(%NGOChal{status: "active"}) == true
  end

  test "active_challenge?/1 returns false if the challenge is complete or expired" do
    assert NGOChalView.active_challenge?(%NGOChal{status: "completed"}) == false
    assert NGOChalView.active_challenge?(%NGOChal{status: "expired"}) == false
  end
end
