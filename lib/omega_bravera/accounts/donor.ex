defmodule OmegaBravera.Accounts.Donor do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Money.Donation

  schema "donors" do
    field :email, :string
    field :firstname, :string
    field :lastname, :string

    timestamps(type: :utc_datetime)

    has_many(:donations, Donation)
  end

  @doc false
  def changeset(donor, attrs) do
    donor
    |> cast(attrs, [:firstname, :lastname, :email])
    |> validate_required([:firstname, :lastname, :email])
  end
end
