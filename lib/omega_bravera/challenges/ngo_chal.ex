defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  schema "ngo_chals" do
    field :activity, :string
    field :distance_target, :decimal, default: 100
    field :distance_covered, :decimal, default: 0
    field :duration, :integer
    field :milestones, :integer, default: 3
    field :money_target, :decimal
    field :slug, :string
    field :start_date, :utc_datetime
    field :status, :string, default: "Active"
    field :total_pledged, :decimal, default: 0
    field :total_secured, :decimal, default: 0
    belongs_to :user, User
    belongs_to :ngo, NGO

    timestamps()
  end

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, [:activity, :money_target, :distance_target, :distance_covered, :slug, :start_date, :status, :duration, :milestones, :total_pledged, :total_secured])
    |> validate_required([:activity, :money_target, :distance_target, :slug, :start_date, :status, :duration, :milestones])
  end
end
