defmodule OmegaBravera.Repo.Migrations.SetTimestampsToUtc do
  use Ecto.Migration

  def up do
    Enum.map(tables, &alter_timestamps(&1, :utc_datetime))
  end

  def down do
    Enum.map(tables, &alter_timestamps(&1, :naive_datetime))
  end

  defp alter_timestamps(name, type) do
    alter table(name) do
      modify(:inserted_at, type, null: false)
      modify(:updated_at, type, null: false)
    end
  end

  defp tables do
    [
      "activities",
      "credentials",
      "donations",
      "ngo_chals",
      "ngos",
      "settings",
      "str_customers",
      "stravas",
      "teams",
      "tips",
      "users"
    ]
  end
end
