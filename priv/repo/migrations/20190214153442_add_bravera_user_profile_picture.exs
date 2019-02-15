defmodule OmegaBravera.Repo.Migrations.AddBraveraUserProfilePicture do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :profile_picture, :string, default: nil
    end
  end
end
