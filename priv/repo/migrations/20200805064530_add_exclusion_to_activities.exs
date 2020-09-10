defmodule OmegaBravera.Repo.Migrations.AddExclusionToActivities do
  use Ecto.Migration

  def change do
    execute "create extension if not exists btree_gist", ""
    execute "update activities_accumulator set end_date = start_date where end_date is null", ""

    alter table(:activities_accumulator) do
      modify :end_date, :utc_datetime, null: false
    end

    drop constraint(:points, :points_activity_id_fkey)

    alter table(:points) do
      modify :activity_id, references(:activities_accumulator, on_delete: :delete_all)
    end

    execute "delete from activities_accumulator where id in (select a1.id from activities_accumulator a1 inner join activities_accumulator a2 on a2.start_date >= a1.start_date and a2.start_date < a1.end_date and a1.user_id = a2.user_id and a1.id <> a2.id)",
            ""

    create constraint(:activities_accumulator, :start_and_end_date_no_overlap,
             exclude: "gist (user_id WITH =, tsrange(start_date, end_date) WITH &&)"
           )
  end
end
