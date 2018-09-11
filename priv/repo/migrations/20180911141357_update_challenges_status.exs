defmodule OmegaBravera.Repo.Migrations.UpdateChallengesStatus do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Challenges.NGOChal}

  def up do
    from(challenge in NGOChal, where: challenge.status == "Active")
    |> Repo.update_all(set: [status: "active"])

    from(challenge in NGOChal, where: challenge.status == "Complete")
    |> Repo.update_all(set: [status: "complete"])
  end

  def down do
    from(challenge in NGOChal, where: challenge.status == "active")
    |> Repo.update_all(set: [status: "Active"])

    from(challenge in NGOChal, where: challenge.status == "complete")
    |> Repo.update_all(set: [status: "Complete"])
  end
end
