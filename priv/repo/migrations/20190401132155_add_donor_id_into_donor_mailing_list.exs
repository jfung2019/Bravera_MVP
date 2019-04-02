defmodule OmegaBravera.Repo.Migrations.AddDonorIdIntoDonorMailingList do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.Donor, Accounts.DonorOptInMailingList}

  def change do
    alter table(:donor_opt_in_mailing_list) do
      add :donor_id, references(:donors, on_delete: :delete_all)
      modify(:user_id, :id, null: true)
    end

    drop(unique_index(:donor_opt_in_mailing_list, [:user_id, :ngo_id]))

    flush()

    opt_out_donors = Repo.all(
      from(o in DonorOptInMailingList, preload: [:user])
    )

    Enum.map(opt_out_donors, fn opt_out_donor ->
      donor = Repo.get_by(Donor, email: opt_out_donor.user.email)
      if donor do
        Repo.update(Ecto.Changeset.change(opt_out_donor, donor_id: donor.id))
      end
    end)

    create(unique_index(:donor_opt_in_mailing_list, [:donor_id, :ngo_id]))
  end
end
