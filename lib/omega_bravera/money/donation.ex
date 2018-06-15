defmodule OmegaBravera.Money.Donation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Fundraisers.NGO

  schema "donations" do
    field :amount, :decimal
    field :currency, :string
    field :milestone, :integer
    field :status, :string
    field :str_src, :string
    belongs_to :user, User
    belongs_to :ngo_chal, NGOChal
    belongs_to :ngo, NGO

    timestamps()
  end

  @doc false
  def changeset(donation, attrs) do
    donation
    |> cast(attrs, [:amount, :currency, :str_src, :milestone, :status])
    |> validate_required([:amount, :currency, :str_src, :milestone, :status])
  end
end
