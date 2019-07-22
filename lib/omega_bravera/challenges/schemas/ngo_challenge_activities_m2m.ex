defmodule OmegaBravera.Challenges.NgoChallengeActivitiesM2m do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  alias OmegaBravera.Activity.{ActivityAccumulator, ActivityOptions}
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
    |> activity_type_matches_challenge_activity_type(activity, ngo_challenge)
  end

  def activity_type_matches_challenge_activity_type(changeset, %{type: activity_type}, %{
        activity_type: challenge_activity_type
      }) do
    accepted_types = ActivityOptions.accepted_activity_types()
    sub_types = accepted_types[challenge_activity_type]

    case sub_types do
      nil ->
        add_error(changeset, :activity_id, "Activity type not supported.")

      types ->
        if not Enum.member?(types, activity_type) do
          Logger.info(
            "Challenge activity type: #{challenge_activity_type} is not same as Activity type: #{
              activity_type
            }"
          )

          add_error(changeset, :activity_id, "Activity type not allowed")
        else
          changeset
        end
    end
  end
end
