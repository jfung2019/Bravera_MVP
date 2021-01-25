defmodule OmegaBravera.Repo.Migrations.AddLiveToOffer do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Offers.Offer}

  def up do
    alter table("offers") do
      add :live, :boolean, default: false, null: false
    end

    flush()

    from(o in Offer, where: is_nil(o.organization_id))
    |> Repo.update_all(set: [live: true])

    from(o in Offer, where: not is_nil(o.organization_id))
    |> Repo.update_all(set: [live: false])
  end

  def down do
    alter table("offers") do
      remove :live
    end
  end
end
