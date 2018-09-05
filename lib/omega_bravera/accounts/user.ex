defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.{Credential, Setting}
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Stripe.StrCustomer

  @required_attributes [:email]
  @allowed_attributes [:email, :firstname, :lastname]

  schema "users" do
    field :email, :string
    field :firstname, :string, default: "No Name"
    field :lastname, :string, default: "No Name"
    has_one :credential, Credential
    has_one :strava, Strava
    has_one :setting, Setting
    has_many :ngos, NGO
    has_many :ngo_chals, NGOChal
    has_many :donations, Donation
    has_many :str_customers, StrCustomer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email)
  end
end
