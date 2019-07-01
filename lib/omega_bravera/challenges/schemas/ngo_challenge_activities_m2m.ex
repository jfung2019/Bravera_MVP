defmodule OmegaBravera.Challenges.NgoChallengeActivitiesM2m do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Activity.{ActivityAccumulator}
  alias OmegaBravera.Challenges.NGOChal

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ngo_challenge_activities_m2m" do
    belongs_to(:activity, ActivityAccumulator)
    belongs_to(:challenge, NGOChal)
  end

  def changeset(activity, ngo_challenge) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_change(:activity_id, activity.id)
    |> put_change(:challenge_id, ngo_challenge.id)
    |> validate_required([:activity_id, :challenge_id])
    |> unique_constraint(:challenge_id_activity_id,
      name: :one_activity_instance_per_ngo_challenge
    )
  end
end
