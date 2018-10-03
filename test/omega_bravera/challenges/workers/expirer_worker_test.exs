defmodule OmegaBravera.Challenges.ExpirerWorkerTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Challenges.{ExpirerWorker, NGOChal}

  describe "process_inactive_challenges/0" do
    test "updates inactive challenges" do
      two_months_ago = Timex.shift(Timex.now(), days: -60)
      one_month_ago = Timex.shift(Timex.now(), days: -30)

      active_challenge = insert(:ngo_challenge)

      expired_challenge =
        insert(:ngo_challenge, %{start_date: two_months_ago, end_date: one_month_ago})

      assert expired_challenge.status == "active"

      ExpirerWorker.process_expired_challenges()

      assert Repo.get!(NGOChal, expired_challenge.id).status == "expired"
      assert Repo.get!(NGOChal, active_challenge.id).status == "active"
    end
  end
end
