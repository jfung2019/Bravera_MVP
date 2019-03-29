defmodule OmegaBravera.Repo.Migrations.RemoveDonorsFromUsers do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.User, Trackers.Strava}

  def change do
    drop(constraint("donations", :donations_user_id_fkey))

    alter table("donations") do
      remove :user_id
    end

    flush()

    # Separate donors only from from users and delete them.
    strava_users_ids = from(s in Strava, select: s.user_id) |> Repo.all()
    Repo.delete_all(from(u in User, where: u.id not in ^strava_users_ids))
  end

end
