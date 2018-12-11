defmodule OmegaBravera.Repo.Migrations.AddChallengePreRegistrationDates do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :pre_registration_start_date, :utc_datetime
      add :pre_registration_end_date, :utc_datetime
      add :open_registration, :boolean, default: false
    end
  end
end
