defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Challenges.Team

  schema "ngo_chals" do
    field :activity, :string
    field :distance_target, :integer, default: 100
    field :distance_covered, :decimal, default: 0
    field :duration, :integer
    field :milestones, :integer, default: 4
    field :money_target, :decimal, default: 2000
    field :default_currency, :string, default: "hkd"
    field :slug, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :status, :string, default: "Active"
    field :total_pledged, :decimal, default: 0
    field :total_secured, :decimal, default: 0
    belongs_to :user, User
    belongs_to :ngo, NGO
    belongs_to :team, Team
    has_many :donations, Donation

    timestamps()
  end

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, [:activity, :money_target, :distance_target, :distance_covered, :slug, :start_date, :end_date, :status, :duration, :milestones, :total_pledged, :total_secured, :default_currency])
    |> validate_required([:activity, :money_target, :distance_target, :start_date, :end_date, :status, :duration, :milestones])
  end
end
