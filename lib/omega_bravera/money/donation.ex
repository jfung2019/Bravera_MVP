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
    field :milestone_distance, :integer
    belongs_to :user, User
    belongs_to :ngo_chal, NGOChal
    belongs_to :ngo, NGO

    timestamps()
  end

  @allowed_attributes [:amount, :currency, :str_src, :str_cus_id, :milestone, :status, :milestone_distance, :user_id, :ngo_chal_id, :ngo_id]
  @required_attributes [:amount, :currency, :str_src, :str_cus_id, :milestone, :status, :user_id, :ngo_chal_id, :ngo_id]

  @doc false
  def changeset(donation, attrs) do
    donation
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
  end
end
