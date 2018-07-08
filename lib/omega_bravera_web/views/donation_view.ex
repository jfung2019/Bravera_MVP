defmodule OmegaBraveraWeb.DonationView do
  use OmegaBraveraWeb, :view

  import Numbers
  import Decimal

  defmodule FormBuilder do
# TODO Add distance format (km/mi)

    def build_milestones(f, total_milestones, total_distance) do

      distance_targets = case total_distance do
          50 -> %{1 => 0, 2 => 15, 3 => 25, 4 => 50}
          75 -> %{1 => 0, 2 => 25, 3 => 45, 4 => 75}
          150 -> %{1 => 0, 2 => 50, 3 => 100, 4 => 150}
          250 -> %{1 => 0, 2 => 75, 3 => 150, 4 => 250}
        end

      milestoneInputs(f, total_milestones, distance_targets)
    end


    defp milestoneInputs(f, n, _distance_targets) when n <= 1 do

      m = :kickstarter
      [
        [
          label(f, "Starting donation", class: "control-label"),

          number_input(f, m, step: "any", class: "form-control", min: "25", id: "kickstarter"),

          error_tag(f, m)
        ]
      ]  # Must be a list too
    end

# TODO stop creating atoms

    defp milestoneInputs(f, n, distance_targets) do

      m = case n do
            4 -> :milestone_3
            3 -> :milestone_2
            2 -> :milestone_1
          end

      %{^n => target} = distance_targets

      [
        [
          label(f, "Milestone #{n - 1} at #{target}km", class: "control-label"),

          number_input(f, m, step: "any", class: "form-control", min: "25", id: "milestone_#{n - 1}"),

          error_tag(f, m)
        ] | milestoneInputs(f, n - 1, distance_targets)]
    end
    #
    # defp milestoneInputs(f, n, marker) when n <= 1 do
    #   current_marker = Numbers.mult(n, marker)
    #
    #   m = :milestone_1
    #   [
    #     [
    #       label(f, "Milestone #{n} at #{current_marker}km", class: "control-label"),
    #
    #       number_input(f, m, step: "any", class: "form-control", min: "25"),
    #
    #       error_tag(f, m)
    #     ]
    #   ]  # Must be a list too
    # end
    #
    # defp milestoneInputs(f, n, marker) do
    #   current_marker = Numbers.mult(n, marker)
    #
    #   m = case n do
    #         6 -> :milestone_6
    #         5 -> :milestone_5
    #         4 -> :milestone_4
    #         3 -> :milestone_3
    #         2 -> :milestone_2
    #       end
    #   [
    #     [
    #       label(f, "Milestone #{n} at #{current_marker}km", class: "control-label"),
    #
    #       number_input(f, m, step: "any", class: "form-control", min: "25"),
    #
    #       error_tag(f, m)
    #     ] | milestoneInputs(f, n - 1, marker)]
    # end

  end
end
