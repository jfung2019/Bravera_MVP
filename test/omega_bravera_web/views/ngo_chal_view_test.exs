defmodule OmegaBraveraWeb.NGOChalViewTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Challenges.NGOChal, Accounts.User}
  alias OmegaBraveraWeb.NGOChalView

  test "active_challenge?/1 returns true if the challenge is active" do
    assert NGOChalView.active_challenge?(%NGOChal{status: "active"}) == true
  end

  test "active_challenge?/1 returns false if the challenge is complete or expired" do
    assert NGOChalView.active_challenge?(%NGOChal{status: "completed"}) == false
    assert NGOChalView.active_challenge?(%NGOChal{status: "expired"}) == false
  end

  test "challenger_not_self_donated?/2 returns whether the challenge owner has donated to the challenge" do
    assert NGOChalView.challenger_not_self_donated?(
             %NGOChal{self_donated: false, user_id: 1},
             %User{id: 1}
           ) == true

    assert NGOChalView.challenger_not_self_donated?(
             %NGOChal{self_donated: true, user_id: 1},
             %User{id: 1}
           ) == false

    assert NGOChalView.challenger_not_self_donated?(
             %NGOChal{self_donated: true, user_id: 2},
             %User{id: 1}
           ) == false

    assert NGOChalView.challenger_not_self_donated?(
             %NGOChal{self_donated: true, user_id: 2},
             false
           ) == false
  end

  describe "render_percentage/3" do
    test "0 done, against 100 km, can be any amount" do
      assert NGOChalView.render_percentage(100, 0) == 0
    end

    test "60 out of 120" do
      assert NGOChalView.render_percentage(120, 60) == 50
    end

    test "120 out of 120" do
      assert NGOChalView.render_percentage(120, 120) == 100
    end

    test "130 out of 120" do
      assert NGOChalView.render_percentage(120, 130) == 100
    end

    test "10 out of 120 with 20 previous" do
      assert NGOChalView.render_percentage(120, 10, 20) == 0
    end

    test "30 out of 120 with 20 previous" do
      assert NGOChalView.render_percentage(120, 30, 20) == 8.33
    end

    test "30 out of 120 decimal with 20 previous decimals" do
      assert NGOChalView.render_percentage(Decimal.new(120), 30, Decimal.new(20)) == 8.33
    end

    test "30 decimal out of 120 decimal with 20 previous decimal" do
      assert NGOChalView.render_percentage(Decimal.new(120), Decimal.new(30), Decimal.new(20)) ==
               8.33
    end

    test "30 out of 120 decimal with 20 previous" do
      assert NGOChalView.render_percentage(Decimal.new(120), 30, 20) == 8.33
    end

    test "130 out of 120 with 20 previous" do
      assert NGOChalView.render_percentage(120, 130, 20) == 100
    end
  end
end
