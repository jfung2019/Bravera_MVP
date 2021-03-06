defmodule OmegaBraveraWeb.DonationView do
  use OmegaBraveraWeb, :view

  defmodule FormBuilder do
    # TODO Add distance format (km/mi)

    def build_milestones(f, total_milestones, total_distance) do
      distance_targets =
        case total_distance do
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
          number_input(f, m,
            step: "any",
            class: "form-control text-center milestone-donations",
            id: "kickstarter"
          ),
          error_tag(f, m)
        ]
      ]

      # Must be a list too
    end

    defp milestoneInputs(f, n, distance_targets) do
      m =
        case n do
          4 -> :milestone_3
          3 -> :milestone_2
          2 -> :milestone_1
        end

      %{^n => target} = distance_targets

      [
        [
          label(f, "Milestone #{n - 1}: #{target}km",
            class: "control-label",
            value: "Milestone #{n - 1}: #{target}km"
          ),
          number_input(f, m,
            step: "any",
            class: "form-control text-center milestone-donations",
            min: "25",
            id: "milestone_#{n - 1}"
          ),
          error_tag(f, m)
        ]
        | milestoneInputs(f, n - 1, distance_targets)
      ]
    end
  end
end
