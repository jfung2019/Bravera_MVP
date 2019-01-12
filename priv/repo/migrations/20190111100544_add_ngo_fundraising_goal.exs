defmodule OmegaBravera.Repo.Migrations.AddNgoFundraisingGoal do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :fundraising_goal, :integer, null: false, default: 0
    end
  end
end
