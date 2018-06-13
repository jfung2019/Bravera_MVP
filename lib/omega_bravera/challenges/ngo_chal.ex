defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  schema "ngo_chals" do
    field :activity, :string
    field :distance_target, :decimal
    field :duration, :integer
    field :money_target, :decimal
    field :slug, :string
    field :start_date, :utc_datetime
    field :status, :string
    belongs_to :user, User
    belongs_to :ngo, NGO

    timestamps()
  end

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, [:activity, :money_target, :distance_target, :slug, :start_date, :status, :duration])
    |> validate_required([:activity, :money_target, :distance_target, :slug, :start_date, :status, :duration])
  end
end
