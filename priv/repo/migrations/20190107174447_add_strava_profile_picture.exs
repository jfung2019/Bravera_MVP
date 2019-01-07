defmodule OmegaBravera.Repo.Migrations.AddStravaProfilePicture do
  use Ecto.Migration

  def change do
    alter table(:stravas) do
      add(:profile_picture, :string, default: nil)
    end
  end
end
