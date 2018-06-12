defmodule OmegaBravera.Trackers.Strava do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Accounts.User


  schema "stravas" do
    field :athlete_id, :integer
    field :email, :string
    field :firstname, :string
    field :lastname, :string
    field :token, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(strava, attrs) do
    strava
    |> cast(attrs, [:email, :athlete_id, :firstname, :lastname, :token])
    |> validate_required([:email, :athlete_id, :firstname, :lastname, :token])
  end
end
