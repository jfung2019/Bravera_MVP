defmodule OmegaBravera.Repo.Migrations.CreateDonorOptInMailingList do
  use Ecto.Migration

  def up do
    create table(:donor_opt_in_mailing_list) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:ngo_id, references(:ngos, on_delete: :delete_all), null: false)
      add(:opt_in, :boolean, default: true)

      timestamps(type: :timestamptz)
    end

    create(unique_index(:donor_opt_in_mailing_list, [:user_id, :ngo_id]))
  end

  def down do
    drop(table(:donor_opt_in_mailing_list))
  end
end
