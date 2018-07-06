defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation

  schema "ngos" do
    field :desc, :string
    field :logo, :string
    field :image, :string
    field :name, :string
    field :slug, :string
    field :stripe_id, :string
    field :url, :string
    field :full_desc, :string
    belongs_to :user, User
    has_many :ngo_chals, NGOChal
    has_many :donations, Donation

    timestamps()
  end

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, [:name, :desc, :logo, :image, :stripe_id, :slug, :url, :full_desc])
    |> validate_required([:name, :stripe_id, :slug])
  end
end
