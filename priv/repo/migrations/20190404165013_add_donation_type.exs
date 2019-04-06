defmodule OmegaBravera.Repo.Migrations.AddDonationType do
  use Ecto.Migration

  import Ecto.Query
  alias OmegaBravera.{Money.Donation, Repo}

  def change do
    alter table("donations") do
      add :type, :string
    end

    flush()

    Repo.update_all((from d in Donation, where: not is_nil(d.milestone)), set: [type: "milestone"])
    Repo.update_all((from d in Donation, where: is_nil(d.milestone)), set: [type: "km"])

  end
end
