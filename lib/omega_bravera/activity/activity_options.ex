defmodule OmegaBravera.Activity.ActivityOptions do
  @activity_allowed_groups %{
    "Run" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Walk" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Hike" => ["Run", "Walk", "Hike", "VirtualRun"],
    "Ride" => ["Ride", "VirtualRun"],
    "Cycle" => ["Cycle", "Ride", "VirtualRun"]
  }

  def accepted_activity_types, do: @activity_allowed_groups
end
