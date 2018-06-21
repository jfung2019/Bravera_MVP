defmodule OmegaBravera.Challenges.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.NGOChal

  schema "teams" do
    field :activity, :string
    field :location, :string
    field :name, :string
    belongs_to :user, User
    belongs_to :ngo, NGO
    has_many :ngo_chals, NGOChal

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:activity, :name, :location])
    |> validate_required([:activity, :name, :location])
  end
end
