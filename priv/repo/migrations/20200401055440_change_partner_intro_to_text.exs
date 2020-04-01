defmodule OmegaBravera.Repo.Migrations.ChangePartnerIntroToText do
  use Ecto.Migration

  def change do
    alter table(:partners) do
      modify :introduction, :text, from: :string
    end
  end
end
