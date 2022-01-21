defmodule OmegaBravera.Repo.Migrations.AddUserAggregateView do
  use Ecto.Migration

  def change do
    execute """
                        CREATE MATERIALIZED VIEW user_agg as
                        SELECT u.id AS user_id,
                            SUM(a.distance) AS distance,
                        	MAX(a.end_date) as end_date,
                            SUM(p.value) AS points_value,
                            MAX(p.inserted_at) as points_date
                           FROM users u
                             LEFT JOIN activities_accumulator a ON u.id = a.user_id
                             LEFT JOIN points p ON p.user_id = u.id
                          GROUP BY u.id
            """,
            "DROP MATERIALIZED VIEW user_agg"

    create unique_index("user_agg", [:user_id])
  end
end
