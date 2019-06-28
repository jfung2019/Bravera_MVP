defmodule OmegaBravera.Offers.OfferChallengeActivitiesM2m do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Activity.{ActivityAccumulator}
  alias OmegaBravera.Offers.{OfferChallenge}

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "offer_challenge_activities_m2m" do
    belongs_to(:activity, ActivityAccumulator)
    belongs_to(:offer_challenge, OfferChallenge)
  end

  def changeset(activity, offer_challenge) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_change(:activity_id, activity.id)
    |> put_change(:offer_challenge_id, offer_challenge.id)
    |> validate_required([:activity_id, :offer_challenge_id])
    |> unique_constraint(:offer_challenge_id_activity_id,
      name: :one_activity_instance_per_offer_challenge
    )
  end
end
