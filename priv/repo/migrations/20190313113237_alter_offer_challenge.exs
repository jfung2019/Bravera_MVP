defmodule OmegaBravera.Repo.Migrations.AlterOfferChallenge do
  use Ecto.Migration

  def change do
    alter table("offer_challenges") do
      add(:link_qr_code, :text)
      add(:redeem_token, :string)
      add(:redeemed, :integer, default: 0, null: false)
    end
  end
end
