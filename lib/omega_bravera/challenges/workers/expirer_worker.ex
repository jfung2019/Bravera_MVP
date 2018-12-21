defmodule OmegaBravera.Challenges.ExpirerWorker do
  import Ecto.Query, only: [from: 2]
  alias OmegaBravera.{Challenges.NGOChal, Repo}

  def process_expired_challenges() do
    now = Timex.now("Asia/Hong_Kong")

    # TODO: Use the correct timezone with challenge.end_date. Otherwise, challenges will end 7 hours early.
    query =
      from(challenge in NGOChal,
        where: challenge.end_date <= ^now and challenge.status == "active"
      )

    Repo.update_all(query, set: [status: "expired"])
  end
end
