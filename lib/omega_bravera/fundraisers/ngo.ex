defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation

  @derive {Phoenix.Param, key: :slug}
  schema "ngos" do
    field(:desc, :string)
    field(:logo, :string)
    field(:image, :string)
    field(:name, :string)
    field(:slug, :string)
    field(:stripe_id, :string)
    field(:url, :string)
    field(:full_desc, :string)
    belongs_to(:user, User)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [:name, :desc, :logo, :image, :stripe_id, :slug, :url, :full_desc]
  @required_attributes [:name, :stripe_id, :slug]

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
  end
end
