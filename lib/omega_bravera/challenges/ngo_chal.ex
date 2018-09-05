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

  @allowed_attributes [
    :activity, :money_target, :distance_target, :distance_covered, :slug, :start_date, :end_date,
    :status, :duration, :milestones, :total_pledged, :total_secured, :default_currency,
    :user_id, :ngo_id
  ]

  @required_attributes [
    :activity, :money_target, :distance_target,
    :start_date, :end_date, :status, :duration,
    :milestones, :user_id, :ngo_id, :slug
  ]

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> add_start_and_end_dates(attrs)
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %{duration: duration_str}) do
    {duration, _} = Integer.parse(duration_str)
    start_date = Timex.now
    end_date = Timex.shift(start_date, days: duration)


    changeset
    |> change(start_date: start_date)
    |> change(end_date: end_date)
  end

end
