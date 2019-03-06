defmodule OmegaBravera.Repo.Migrations.AddActivityProcessingDetailsToNgoChal do
  use Ecto.Migration

  alias OmegaBravera.{Challenges.NGOChal}

  def change do
    alter table("ngo_chals") do
      add(:last_activity_received, :utc_datetime, default: fragment("NOW()"))
      add(:participant_notified_of_inactivity, :boolean, default: false)
      add(:donor_notified_of_inactivity, :boolean, default: false)
    end
  end
end
