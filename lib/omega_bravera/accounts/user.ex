defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.{Credential, Setting}
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Stripe.StrCustomer

  schema "users" do
    field :email, :string
    field :firstname, :string, default: "Hao"
    field :lastname, :string, default: "Doe"
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
    |> cast(attrs, [:email, :firstname, :lastname])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email)
  end
end
