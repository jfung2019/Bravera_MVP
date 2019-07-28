defmodule OmegaBravera.Activity.ActivityOptions do
  @activity_allowed_groups %{
    "Run" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Walk" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Hike" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Ride" => ["Ride", "VirtualRide"],
    "Cycle" => ["Cycle", "Ride", "VirtualRide"]
  }

  def accepted_activity_types, do: @activity_allowed_groups
  def points_allowed_activities, do: ["Run", "Walk", "Hike", "VirtualRun"]
end
