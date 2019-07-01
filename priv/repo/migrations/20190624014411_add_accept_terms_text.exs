defmodule OmegaBravera.Repo.Migrations.AddAcceptTermsText do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add(:accept_terms_text, :string, null: true)
    end
  end
end
