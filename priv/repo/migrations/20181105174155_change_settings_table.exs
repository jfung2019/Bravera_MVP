defmodule OmegaBravera.Repo.Migrations.ChangeSettingsTable do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      remove(:facebook)
      remove(:instagram)
      remove(:twitter)
      remove(:show_lastname)
      remove(:request_delete)
      remove(:email_notifications)

      add(:weight, :integer, null: true, default: nil)
      add(:date_of_birth, :date, null: true, default: nil)
      add(:gender, :string, null: true, default: nil)
    end
  end
end