defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO

  schema "users" do
    field :email, :string
    field :firstname, :string
    field :lastname, :string
    has_one :strava, Strava
    has_many :ngos, NGO

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
