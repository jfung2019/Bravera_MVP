defmodule OmegaBravera.Repo.Migrations.BlankEmailAddressForDonorUsers do
  use Ecto.Migration
  import Ecto.Query
  alias OmegaBravera.{Accounts.User, Repo}

  def up do
    empty_donor_user_ids =
      from(u in User,
        left_join: d in assoc(u, :donations),
        left_join: s in assoc(u, :strava),
        where: is_nil(s.id),
        select: u.id,
        group_by: u.id,
        having: sum(d.id) > 0
      )

    Repo.update_all(from(u in User, join: s in subquery(empty_donor_user_ids), on: s.id == u.id),
      set: [email: nil]
    )
  end

  def down do
  end
end
