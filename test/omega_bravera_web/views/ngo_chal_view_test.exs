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

  test "currency_to_symbol/1 as USD returns $" do
    assert NGOChalView.currency_to_symbol("usd") == "$"
  end

  test "currency_to_symbol/1 as MYR returns RM" do
    assert NGOChalView.currency_to_symbol("myr") == "RM"
  end

  test "currency_to_symbol/1 as HKD returns HK$" do
    assert NGOChalView.currency_to_symbol("hkd") == "HK$"
  end

  test "currency_to_symbol/1 as krw returns ₩" do
    assert NGOChalView.currency_to_symbol("krw") == "₩"
  end

  test "currency_to_symbol/1 as sgd returns ₩" do
    assert NGOChalView.currency_to_symbol("sgd") == "S$"
  end

  test "currency_to_symbol/1 as gbp returns ₩" do
    assert NGOChalView.currency_to_symbol("gbp") == "£"
  end
end
