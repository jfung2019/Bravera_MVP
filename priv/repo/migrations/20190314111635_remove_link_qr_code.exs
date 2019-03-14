defmodule OmegaBravera.Repo.Migrations.RemoveLinkQrCode do
  use Ecto.Migration

  def change do
    alter table("offer_challenges") do
      remove(:link_qr_code)
    end
  end
end
