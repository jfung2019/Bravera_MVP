defmodule OmegaBravera.Repo.Migrations.AddChallengePreRegistrationDates do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add(:pre_registration_start_date, :utc_datetime)
      add(:launch_date, :utc_datetime)
      add(:open_registration, :boolean, default: true)
    end
  end
end
