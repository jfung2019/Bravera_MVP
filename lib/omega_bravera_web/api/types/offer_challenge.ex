defmodule OmegaBraveraWeb.Api.Types.OfferChallenge do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias OmegaBravera.Offers
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :offer_challenge do
    field :id, :integer
    field :activity_type, :string
    field :default_currency, :string
    field :distance_target, :integer
    field :distance_covered, :decimal
    field :end_date, :date
    field :has_team, :boolean
    field :slug, :string
    field :start_date, :date
    field :status, :string
    field :type, :string
    field :offer_id, :integer
    field :inserted_at, :date
    field :updated_at, :date
    field :user, :user
    field :offer, :offer, resolve: dataloader(Offers)
  end

  connection(node_type: :offer_challenge)

  object :offer_challenge_locked do
    field :user, non_null(:user_locked)
    field :distance_covered, :decimal
    field :start_date, :date
    field :end_date, :date
  end

  connection(node_type: :offer_challenge_locked)

  object :offer_challenges_map do
    field :total, :integer
    field :live, list_of(:offer_challenge)
    field :expired, list_of(:offer_challenge)
    field :completed, list_of(:offer_challenge)
  end

  input_object :offer_challenge_create_input do
    field :offer_slug, :string
  end

  # For success/error reporting
  object :offer_challenge_create_result do
    field(:offer_challenge, :offer_challenge)
    field(:errors, list_of(:input_error))
  end

  object :buy_or_create_offer_challenge_result do
    field(:offer_challenge, :offer_challenge)
    field(:user_profile, :user_profile)
  end
end
