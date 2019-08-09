defmodule OmegaBraveraWeb.Schema.Types.OfferChallenge do
  use Absinthe.Schema.Notation

  object :offer_challenge do
    field(:id, :id)
    field(:activity_type, :string)
    field(:default_currency, :string)
    field(:distance_target, :integer)
    field(:end_date, :date)
    field(:has_team, :boolean)
    field(:slug, :string)
    field(:start_date, :date)
    field(:status, :string)
    field(:type, :string)
    field(:inserted_at, :date)
    field(:updated_at, :date)
  end
end
