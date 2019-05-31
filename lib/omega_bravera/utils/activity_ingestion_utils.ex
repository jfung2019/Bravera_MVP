defmodule OmegaBravera.ActivityIngestionUtils do
  require Logger

  def activity_type_matches_challenge_activity_type?(%{type: "Ride"}, %{activity_type: "Cycle"}),
    do: true

  def activity_type_matches_challenge_activity_type?(%{type: activity_type}, %{
        activity_type: challenge_activity_type
      }) do
    validate(activity_type, challenge_activity_type)
  end

  defp validate(activity_type, challenge_activity_type)
       when activity_type == challenge_activity_type,
       do: true

  defp validate(activity_type, challenge_activity_type)
       when activity_type != challenge_activity_type do
    Logger.info(
      "Challenge activity type: #{challenge_activity_type} is not same as Activity type: #{
        activity_type
      }"
    )

    false
  end
end
