defmodule OmegaBravera.Repo.Migrations.CreatePoints do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Points.Point, Activity.ActivityAccumulator}

  def up do
    create table(:points) do
      add(:value, :decimal, null: false)
      add(:source, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:activity_id, references(:activities_accumulator, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    flush()

    create(unique_index(:points, [:activity_id], name: :activity_already_taken))

    flush()

    point_entries =
      from(a in "activities_accumulator", select: [:user_id, :id, :inserted_at, :updated_at])
      |> Repo.all()
      |> Enum.map(fn activity ->
        value =
          activity.distance
          |> Decimal.round(2, :floor)
          |> Decimal.mult(Decimal.new(10))

        if Enum.member?(["Run", "Walk", "Hike", "VirtualRun"], activity.type) do
          [
            source: "activity",
            user_id: activity.user_id,
            activity_id: activity.id,
            value: value,
            inserted_at: DateTime.truncate(Timex.now(), :second),
            updated_at: DateTime.truncate(Timex.now(), :second)
          ]
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Repo.insert_all(Point, point_entries)
  end

  def down do
    drop(table(:points))
  end
end
