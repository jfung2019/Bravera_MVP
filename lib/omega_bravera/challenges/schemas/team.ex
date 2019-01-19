defmodule OmegaBravera.Challenges.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Challenges.NGOChal}

  @allowed_attributes [:name, :slug, :challenge_id, :user_id]
  @required_attributes @allowed_attributes

  @derive {Phoenix.Param, key: :slug}
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
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> unique_constraint(:slug, name: :teams_name_index)
  end
end
