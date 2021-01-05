defmodule OmegaBravera.Repo.Migrations.SetDefaultValue do
  use Ecto.Migration

  def up do
    alter table("offers") do
      modify :offer_challenge_types, {:array, :string}, default: ["PER_KM"]
      modify :activities, {:array, :string}, default: ["Run"]
      modify :url, :string, default: "https://www.bravera.fit/"
    end
  end

  def down do
    alter table("offers") do
      modify :offer_challenge_types, {:array, :string}
      modify :activities, {:array, :string}
      modify :url, :string
    end
  end
end
