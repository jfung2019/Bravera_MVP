defmodule OmegaBravera.Repo.Migrations.CreateDonors do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.User, Accounts.Donor, Money.Donation}

  def change do
    create table(:donors) do
      add(:firstname, :string)
      add(:lastname, :string)
      add(:email, :string, null: false)

      timestamps(type: :timestamptz)
    end

    alter table(:donations) do
      add(:donor_id, :id)
    end

    flush()

    unique_user_donors =
      from(d in Donation, select: d.user_id)
      |> Repo.all()
      |> Enum.uniq()

    # Get all users who made a donation.
    users_who_donated =
      from(u in User, where: u.id in ^unique_user_donors, preload: [:donations])
      |> Repo.all()

    donor_entries =
      Enum.map(
        users_who_donated,
        &%{
          firstname: &1.firstname,
          lastname: &1.lastname,
          email: &1.email,
          inserted_at: &1.inserted_at,
          updated_at: &1.updated_at
        }
      )

    # Insert users who donated as donors.
    Repo.insert_all(Donor, donor_entries)

    # Add donor_id to each donation
    Enum.map(users_who_donated, fn user_who_donated ->
      Enum.map(user_who_donated.donations, fn donation ->
        donor = Repo.get_by(Donor, email: user_who_donated.email)

        Repo.update(Ecto.Changeset.change(donation, donor_id: donor.id))
      end)
    end)
  end
end
