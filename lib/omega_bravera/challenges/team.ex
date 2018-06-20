defmodule OmegaBravera.Challenges.Team do
  use Ecto.Schema
  import Ecto.Changeset


  schema "teams" do
    field :activity, :string
    field :location, :string
    field :name, :string
    field :user_id, :id
    field :ngo_id, :id

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:activity, :name, :location])
    |> validate_required([:activity, :name, :location])
  end
end
