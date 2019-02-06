defmodule OmegaBravera.Repo.Migrations.CreateDonorOptInMailingList do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.DonorOptInMailingList, Money.Donation}

  def up do
    create table(:donor_opt_in_mailing_list) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :ngo_id, references(:ngos, on_delete: :delete_all), null: false
      add :opt_in, :boolean, default: true

      timestamps(type: :timestamptz)
    end

    create unique_index(:donor_opt_in_mailing_list, [:user_id, :ngo_id])

    flush()

    donors =
      from(
        d in Donation,
        distinct: true,
        select: %{
          user_id: d.user_id,
          ngo_id: d.ngo_id
        }
      )
      |> Repo.all()

    donors_with_timestamps =
      donors
      |> Enum.map(fn donor ->
        donor
        |> Map.put(:inserted_at, Timex.now)
        |> Map.put(:updated_at, Timex.now)
      end)

    Repo.insert_all(DonorOptInMailingList, donors_with_timestamps)
  end

  def down do
    drop table(:donor_opt_in_mailing_list)
  end
end
