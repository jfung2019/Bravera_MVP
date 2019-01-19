defmodule OmegaBravera.Challenges.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Challenges.NGOChal}

  schema "teams" do
    field(:name, :string)
    field(:slug, :string)

    belongs_to(:user, User)
    belongs_to(:challenge, NGOChal)
    # TODO: add members assoc

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
