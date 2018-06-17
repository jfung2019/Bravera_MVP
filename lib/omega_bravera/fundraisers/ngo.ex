defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal

  schema "ngos" do
    field :desc, :string
    field :logo, :string
    field :name, :string
    field :slug, :string
    field :stripe_id, :string
    belongs_to :user, User
    has_many :ngo_chals, NGOChal

    timestamps()
  end

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, [:name, :desc, :logo, :stripe_id, :slug])
    |> validate_required([:name, :stripe_id, :slug])
  end
end
