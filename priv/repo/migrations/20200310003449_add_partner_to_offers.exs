defmodule OmegaBravera.Repo.Migrations.AddPartnerToOffers do
  use Ecto.Migration

  def change do
    alter table(:offers) do
      add(:partner_id, references(:partners, on_delete: :nilify_all), null: true)
    end
  end
end
