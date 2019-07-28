defmodule OmegaBravera.Repo.Migrations.CreatePoints do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Points.Point, Activity.ActivityAccumulator}

  def up do
    create table(:points) do
      add(:balance, :integer, null: false)
      add(:source, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:activity_id, references(:activities_accumulator, on_delete: :nothing))
    end

    flush()

    create(unique_index(:points, [:activity_id], name: :activity_already_taken))

    flush()

    point_entries =
      from(a in ActivityAccumulator)
      |> Repo.all()
      |> Enum.map(fn activity ->
        int_distance = activity.distance |> Decimal.round() |> Decimal.to_integer()

        balance =
          cond do
            int_distance > 1 -> int_distance * 10
            int_distance < 1 -> 0
            int_distance == 1 -> 10
          end

        if balance > 1 and !Enum.member?(["Cycle", "Ride", "VirtualRide"], activity.type) do
          [
            source: "activity",
            user_id: activity.user_id,
            activity_id: activity.id,
            balance: balance
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
