defmodule OmegaBravera.Challenges.ExpirerWorker do
  import Ecto.Query, only: [from: 2]
  alias OmegaBravera.{Challenges, Challenges.NGOChal, Repo}

  def process_expired_challenges() do
    now = Timex.now()
    query = from(challenge in NGOChal, where: challenge.end_date <= ^now and challenge.status == "active")

    Repo.update_all(query, set: [status: "expired"])
  end
end
