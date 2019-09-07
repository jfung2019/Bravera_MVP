defmodule OmegaBraveraWeb.Api.Types.OfferChallenge do
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

  object :offer_challenges_map do
    field(:live, list_of(:offer_challenge))
    field(:expired, list_of(:offer_challenge))
    field(:completed, list_of(:offer_challenge))
  end

  input_object :offer_challenge_create_input do
    field(:offer_slug, :string)
  end

  # For success/error reporting
  object :offer_challenge_create_result do
    field(:offer_challenge, :offer_challenge)
    field(:errors, list_of(:input_error))
  end
end
