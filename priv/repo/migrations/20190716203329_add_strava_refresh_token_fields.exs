defmodule OmegaBravera.Repo.Migrations.AddStravaRefreshTokenFields do
  use Ecto.Migration

  def up do
    alter table("stravas") do
      add(:refresh_token, :string)
      add(:token_expires_at, :utc_datetime)
    end
  end

  def down do
    alter table("stravas") do
      remove(:refresh_token)
      remove(:token_expires_at)
    end
  end
end
