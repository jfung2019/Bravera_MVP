defmodule OmegaBravera.Money.Donation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Fundraisers.NGO

  # TODO do we need str_source or str_customer here ?
  # I think we do...

  schema "donations" do
    field :amount, :decimal
    field :currency, :string
    field :milestone, :integer
    field :status, :string, default: "pending"
    field :str_src, :string
    field :str_cus_id, :string
    belongs_to :user, User
    belongs_to :ngo_chal, NGOChal
    belongs_to :ngo, NGO

    timestamps()
  end

  @doc false
  def changeset(donation, attrs) do
    donation
    |> cast(attrs, [:amount, :currency, :str_src, :str_cus_id, :milestone, :status])
    |> validate_required([:amount, :currency, :str_src, :str_cus_id, :milestone, :status])
  end
end
