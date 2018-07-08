defmodule OmegaBraveraWeb.DonationView do
  use OmegaBraveraWeb, :view

  import Numbers
  import Decimal

  defmodule FormBuilder do
# TODO Add distance format (km/mi)

    def build_milestones(f, total_milestones, total_distance) do
      milestone_marker = Numbers.div(total_distance, total_milestones)

      milestoneInputs(f, total_milestones, milestone_marker)
    end

    defp milestoneInputs(f, n, marker) when n <= 1 do
      current_marker = Numbers.mult(n, marker)

      m = :milestone_1
      [
        [
          label(f, "Milestone #{n} at #{current_marker}km", class: "control-label"),

          number_input(f, m, step: "any", class: "form-control"),

          error_tag(f, m)
        ]
      ]  # Must be a list too
    end

    defp milestoneInputs(f, n, marker) do
      current_marker = Numbers.mult(n, marker)

      m = case n do
            6 -> :milestone_6
            5 -> :milestone_5
            4 -> :milestone_4
            3 -> :milestone_3
            2 -> :milestone_2
          end
      [
        [
          label(f, "Milestone #{n} at #{current_marker}km", class: "control-label"),

          number_input(f, m, step: "any", class: "form-control"),

          error_tag(f, m)
        ] | milestoneInputs(f, n - 1, marker)]
    end

  end
end
