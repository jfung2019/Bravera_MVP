defmodule OmegaBravera.Repo.Migrations.AddFormUrlToOffers do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add :form_url, :string
    end
  end
end
