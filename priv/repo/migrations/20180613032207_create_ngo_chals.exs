defmodule OmegaBravera.Repo.Migrations.CreateNgoChals do
  use Ecto.Migration

  def change do
    create table(:ngo_chals) do
      add :activity, :string
      add :money_target, :decimal
      add :distance_target, :decimal
      add :slug, :string
      add :start_date, :utc_datetime
      add :status, :string
      add :duration, :integer
      add :user_id, references(:user, on_delete: :nothing)
      add :ngo_id, references(:ngo, on_delete: :nothing)

      timestamps(type: :timestamptz)
    end

    create index(:ngo_chals, [:user_id])
    create index(:ngo_chals, [:ngo_id])
  end
end
