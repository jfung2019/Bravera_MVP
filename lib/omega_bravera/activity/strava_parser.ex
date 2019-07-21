defmodule OmegaBravera.Activity.StravaParser do
  def strava_activity_to_map(strava_activity) do
    strava_activity
    |> to_map()
    |> parse_athlete
    |> parse_photos
    |> parse_laps()
    |> parse_splits_metric()
    |> parse_splits_standard()
    |> parse_gear()
    |> parse_map()
    |> parse_segment_efforts()
    |> parse_best_efforts()
  end

  defp to_map(%_{} = value), do: Map.from_struct(value)
  defp to_map(%{} = value), do: value
  defp to_map(nil), do: nil

  defp parse_athlete(%{athlete: athlete} = activity),
    do: %{activity | athlete: to_map(athlete)}

  defp parse_photos(activity)
  defp parse_photos(%{photos: nil} = activity), do: activity

  defp parse_photos(%{photos: photos} = activity) do
    %{activity | photos: to_map(photos)}
  end

  defp parse_segment_efforts(activity)
  defp parse_segment_efforts(%{segment_efforts: nil} = activity), do: activity

  defp parse_segment_efforts(%{segment_efforts: segment_efforts} = activity) do
    %{
      activity
      | segment_efforts:
          Enum.map(segment_efforts, fn segment_effort ->
            to_map(segment_effort)
            |> parse_segment()
          end)
    }
  end

  defp parse_segment(%{segment: segment} = segment_effort) do
    %{segment_effort | segment: to_map(segment)}
    |> parse_meta_activity()
    |> parse_meta_athlete()
  end

  defp parse_laps(activity)
  defp parse_laps(%{laps: nil} = activity), do: activity

  defp parse_laps(%{laps: laps} = activity) do
    %{
      activity
      | laps:
          Enum.map(laps, fn lap ->
            to_map(lap)
            |> parse_meta_activity()
            |> parse_meta_athlete()
          end)
    }
  end

  defp parse_splits_metric(activity)
  defp parse_splits_metric(%{splits_metric: nil} = activity), do: activity

  defp parse_splits_metric(%{splits_metric: splits_metric} = activity),
    do: %{ activity | splits_metric: Enum.map(splits_metric, &(to_map(&1)))}

  defp parse_splits_standard(activity)
  defp parse_splits_standard(%{splits_standard: nil} = activity), do: activity

  defp parse_splits_standard(%{splits_standard: splits_standard} = activity),
    do: %{ activity | splits_standard: Enum.map(splits_standard, &(to_map(&1)))}

  defp parse_gear(activity)
  defp parse_gear(%{gear: nil} = activity), do: activity

  defp parse_gear(%{gear: gear} = activity),
    do: %{ activity | gear: to_map(gear)}

  defp parse_map(activity)
  defp parse_map(%{map: nil} = activity), do: activity

  defp parse_map(%{map: map} = activity),
    do: %{ activity | map: to_map(map)}

  defp parse_best_efforts(activity)
  defp parse_best_efforts(%{best_efforts: nil} = activity), do: activity

  defp parse_best_efforts(%{best_efforts: best_efforts} = activity) do
    %{
      activity
      | best_efforts:
          Enum.map(best_efforts, fn best_effort ->
            to_map(best_effort)
            |> parse_segment()
            |> parse_meta_activity()
            |> parse_meta_athlete()
          end)
    }
  end


  defp parse_meta_activity(%{activity: meta_activity} = activity),
    do: %{activity | activity: to_map(meta_activity)}

  defp parse_meta_athlete(%{athlete: meta_athlete} = activity),
    do: %{activity | athlete: to_map(meta_athlete)}
end
