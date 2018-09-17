defmodule OmegaBravera.Challenges.InactivityWorkerTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory
  import Ecto.Query

  alias OmegaBravera.Challenges.{InactivityWorker, NGOChal}

  describe "process_inactive_challenges/0" do
    test "updates inactive challenges" do
      ngo = insert(:ngo)
      _participant_notifiable = insert(:ngo_challenge, %{last_activity_received:  Timex.shift(Timex.now, days: -6), slug: "John-325", ngo: ngo})
      donor_notifiable = insert(:ngo_challenge, %{last_activity_received:  Timex.shift(Timex.now, days: -8), slug: "John-515", ngo: ngo})
      non_notifiable = insert(:ngo_challenge, %{last_activity_received:  Timex.shift(Timex.now, days: -2), slug: "Peter-411", ngo: ngo})

      InactivityWorker.process_inactive_challenges()

      still_active = Repo.all((from c in NGOChal, where: c.participant_notified_of_inactivity == false and c.donor_notified_of_inactivity == false))
      participant_notified = Repo.all((from c in NGOChal, where: c.participant_notified_of_inactivity == true))
      donor_notified = Repo.all((from c in NGOChal, where: c.donor_notified_of_inactivity == true))

      assert hd(still_active).id == non_notifiable.id

      assert length(participant_notified) == 2
      assert hd(donor_notified).id == donor_notifiable.id

    end
  end
end
