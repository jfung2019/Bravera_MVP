defmodule OmegaBravera.Repo.Migrations.FixUserAggQueries do
  use Ecto.Migration

  def change do
    execute "DROP MATERIALIZED VIEW user_agg", """
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
    """

    execute """
            ;
            CREATE MATERIALIZED VIEW user_agg AS
            SELECT u.id AS user_id,
                      a.distance AS distance,
                      a.end_date AS end_date,
                      p.points_value AS points_value,
                      p.points_date AS points_date
                     FROM users u
                       LEFT OUTER JOIN LATERAL(SELECT SUM(distance) AS distance, MAX(end_date) AS end_date, user_id FROM activities_accumulator GROUP BY user_id) AS a ON u.id = a.user_id
                       LEFT OUTER JOIN LATERAL(SELECT SUM(value) AS points_value, MAX(inserted_at) AS points_date, user_id FROM points GROUP BY user_id) AS p ON p.user_id = u.id
            """,
            "DROP MATERIALIZED VIEW user_agg"
  end
end
