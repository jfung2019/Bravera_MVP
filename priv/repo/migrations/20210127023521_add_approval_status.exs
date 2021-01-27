defmodule OmegaBravera.Repo.Migrations.AddApprovalStatus do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Offers.Offer}

  def up do
    alter table("offers") do
      add :approval_status, :string, null: false, default: "pending"
    end

    flush()

    from(o in Offer, where: o.live == true)
    |> Repo.update_all(set: [approval_status: :approved])
  end

  def down do
    alter table("offers") do
      remove :approval_status
    end
  end
end
