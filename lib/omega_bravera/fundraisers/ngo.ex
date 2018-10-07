defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation

  @available_activities ["Run", "Cycle", "Walk", "Hike"]
  @available_distances [50, 75, 150, 250]

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
    field(:currency, :string, default: "hkd")
    field(:activities, {:array, :string}, default: @available_activities)
    field(:distances, {:array, :integer}, default: @available_distances)
    belongs_to(:user, User)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :name,
    :desc,
    :logo,
    :image,
    :stripe_id,
    :slug,
    :url,
    :full_desc,
    :user_id,
    :currency,
    :activities,
    :distances
  ]
  @required_attributes [:name, :stripe_id, :slug]

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_inclusion(:currency, valid_currencies())
    |> validate_subset(:activities, @available_activities)
  end

  def currency_options do
    %{
      "Hong Kong Dollar (HKD)" => "hkd",
      "South Korean Won (KRW)" => "krw",
      "Singapore Dollar (SGD)" => "sgc",
      "Malaysian Ringgit (MYR)" => "myr",
      "United States Dollar (USD)" => "usd",
      "British Pound (GBP)" => "gbp"
    }
  end

  defp valid_currencies, do: Map.values(currency_options())

  def activity_options, do: @available_activities

  def distance_options, do: @available_distances
end

defimpl Phoenix.Param, for: OmegaBravera.Fundraisers.NGO do
  def to_param(%{slug: slug}), do: slug
end
