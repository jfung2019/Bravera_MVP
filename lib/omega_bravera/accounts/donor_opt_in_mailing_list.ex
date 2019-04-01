defmodule OmegaBravera.Accounts.DonorOptInMailingList do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Fundraisers.NGO, Accounts.User, Accounts.Donor}

  schema "donor_opt_in_mailing_list" do
    field(:opt_in, :boolean, default: true)

    belongs_to(:user, User)
    belongs_to(:donor, Donor)
    belongs_to(:ngo, NGO)

    timestamps(type: :utc_datetime)
  end

  def changeset(donor_opt_in_mailing_list, attrs) do
    donor_opt_in_mailing_list
    |> cast(attrs, [:ngo_id, :opt_in, :donor_id])
    |> validate_required([:ngo_id, :opt_in, :donor_id])
    |> unique_constraint(:donor_opt_in_mailing_list_donor_id_ngo_id_index)
  end

  def update_changeset(donor_opt_in_mailing_list, attrs) do
    donor_opt_in_mailing_list
    |> cast(attrs, [:opt_in])
  end
end
