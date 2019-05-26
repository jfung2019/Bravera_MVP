defmodule OmegaBravera.Challenges.ExpirerWorker do
  import Ecto.Query, only: [from: 2]
  alias OmegaBravera.{Offers, Challenges.NGOChal, Repo, Challenges.KmChallengesWorker}

  def process_expired_challenges() do
    # To avoid KM Challenges being expired before they are even charged, we run the KmChallengesWorker
    # before the expirer worker. -Sherief
    KmChallengesWorker.start()

    now = Timex.now()

    query =
      from(challenge in NGOChal,
        where: challenge.end_date <= ^now and challenge.status == "active"
      )

    Repo.update_all(query, set: [status: "expired"])

    query =
      from(challenge in Offers.OfferChallenge,
        where: challenge.end_date <= ^now and challenge.status == "active"
      )

    Repo.update_all(query, set: [status: "expired"])
  end
end
