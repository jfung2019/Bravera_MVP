defmodule OmegaBravera.Repo.Migrations.AddOfferExternalTermsUrl do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add(:external_terms_url, :string)
    end
  end
end
