defmodule OmegaBraveraWeb.NGOChalView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Fundraisers.NGO, Challenges.NGOChal, Trackers.Strava, Accounts.User}

  def user_full_name(%User{} = user), do: User.full_name(user)

  def user_profile_pic(%Strava{athlete_id: athlete_id}) do
    "https://www.strava.com/athletes/#{Integer.to_string(athlete_id)}/avatar?size=large"
  end

  def user_profile_pic(nil), do: ""

  def active_challenge?(%NGOChal{status: "active"}), do: true
  def active_challenge?(%NGOChal{}), do: false

  def pre_registration_challenge?(%NGOChal{status: "pre_registration"}), do: true
  def pre_registration_challenge?(%NGOChal{}), do: false

  def pre_registration_ngo?(%NGO{open_registration: false} = ngo), do: Timex.after?(ngo.launch_date, Timex.now("Asia/Hong_Kong"))
  def pre_registration_ngo?(%NGO{}), do: false


  def challenger_not_self_donated?(%NGOChal{user_id: user_id, self_donated: false}, %User{
        id: user_id
      }),
      do: true

  def challenger_not_self_donated?(_, _), do: false

  # TODO: Move into app logic and delegate
  def currency_to_symbol(currency) do
    case currency do
      "myr" -> "RM"
      "hkd" -> "HK$"
      "krw" -> "₩"
      "sgd" -> "S$"
      "gbp" -> "£"
      _ -> "$"
    end
  end

  def render_percentage(target, current, previous \\ 0)

  def render_percentage(%Decimal{} = target, current, previous) do
    render_percentage(Decimal.to_float(target), current, previous)
  end

  def render_percentage(target, current, %Decimal{} = previous) do
    render_percentage(target, current, Decimal.to_float(previous))
  end

  def render_percentage(target, %Decimal{} = current, previous) do
    render_percentage(target, Decimal.to_float(current), previous)
  end

  def render_percentage(_target, current, previous) when current <= previous, do: 0
  def render_percentage(_target, 0, _previous), do: 0
  def render_percentage(target, current, 0) when current >= target, do: 100
  def render_percentage(target, current, 0), do: current / target * 100
  def render_percentage(target, current, _previous) when current >= target, do: 100

  def render_percentage(target, current, previous) when previous > 0 do
    ((current - previous) / target * 100)
    |> Float.round(2)
  end

  def render_percentage_exceed(total, %Decimal{} = target),
    do: round(total / Decimal.to_integer(target) * 100)

  def render_percentage_exceed(%Decimal{} = total, target),
    do: (Decimal.round(total) |> Decimal.to_integer()) / target * 100

  def render_progress_bar(
        target,
        previous_target,
        %{default_currency: currency, distance_covered: distance},
        total
      ) do
    percentage = render_percentage(target, distance, previous_target)

    {label_class, total_class} =
      if percentage >= 100 do
        {"text-bravera text-500", "float-right text-success"}
      else
        {"milestone-label", "float-right"}
      end

    [
      content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1", style: "text-align: left;") do
        [
          content_tag(:span, "#{target}km", class: label_class),
          content_tag(:span, class: "text-secondary") do
            content_tag(:strong, "#{currency_to_symbol(currency)}#{total || 0}",
              class: total_class
            )
          end
        ]
      end,
      content_tag(:div, "", style: "clear: both;"),
      content_tag(:div, class: "progress milestone-chal-progress mb-2") do
        content_tag(:div, "",
          class: "progress-bar bg-bravera",
          style: "width: #{percentage}%",
          role: "progressbar",
          "aria-valuenow": "",
          "aria-valuemin": "0",
          "aria-valuemax": ""
        )
      end
    ]
  end

  def render_progress_bar(%Decimal{} = distance_covered, distance_target) do
    percentage = render_percentage_exceed(distance_covered, distance_target)

    {label_class, total_class} =
      if percentage >= 100 do
        {"text-bravera text-500", "float-right text-success"}
      else
        {"milestone-label", "float-right"}
      end

    [
      content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1", style: "text-align: left;") do
          content_tag(:div, class: "d-flex justify-content-between bd-highlight mb-3") do
            [
              content_tag(:span, "0", class: "p-2 " <> label_class),
              content_tag(:div, class: "progress km-chal-progress") do
                content_tag(:div, "",
                  class: "progress-bar bg-bravera",
                  style: "width: #{percentage}%",
                  role: "progressbar",
                  "aria-valuenow": "",
                  "aria-valuemin": "0",
                  "aria-valuemax": ""
                )
              end,
              content_tag(:span, class: "p-2 text-secondary") do
                content_tag(:strong, "#{distance_target}KM", class: total_class)
              end
            ]
          end

      end,
      content_tag(:div, "", style: "clear: both;")
    ]
  end

  def render_total_pledged(pending, secured, default_currency) do
    color =
      if pending <= secured and pending != 0 do
        "text-success"
      else
        "text-secondary"
      end

    content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1 text-left #{color}") do
      [
        "Total Pledged ",
        content_tag(
          :i,
          class: "fa fa-question-circle-o text-secondary fa-1",
          data: [
            container: "body",
            toggle: "popover",
            placement: "top",
            title: "Total pledged",
            content: "means 'not yet secured' by either reaching a milestone or finishing a challenge.",
            trigger: "focus"
          ],
          tabindex: "0",
          id: "pledged_tooltip") do end,
        content_tag(:span, class: "float-right") do
          content_tag(
            :strong,
            "#{currency_to_symbol(default_currency) <> Integer.to_string(pending)}"
          )
        end
      ]
    end
  end

  def render_total_secured(secured, default_currency) do
    color =
      if secured <= 0 do
        "text-secondary"
      else
        "text-success"
      end

    content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1 text-left #{color}") do
      [
        "Total Secured ",
        content_tag(
          :i,
          class: "fa fa-question-circle-o text-secondary fa-1",
          data: [
            container: "body",
            toggle: "popover",
            placement: "top",
            title: "Total secured",
            content: "the transaction has been made after hitting a milestone or challenge is completed.",
            trigger: "focus"
          ],
          tabindex: "0",
          id: "secured_tooltip") do end,
        content_tag(:span, class: "float-right") do
          content_tag(
            :strong,
            "#{currency_to_symbol(default_currency) <> Integer.to_string(secured)}"
          )
        end
      ]
    end
  end

  def render_pledge_per_km(nil), do: 0

  def render_pledge_per_km(%Decimal{} = total_km_pledges),
    do: Decimal.to_string(total_km_pledges)

  def render_current_pledge_value(_, nil), do: 0

  def render_current_pledge_value(%Decimal{} = total_km_pledges, %Decimal{} = distance_covered) do
    Decimal.mult(total_km_pledges, distance_covered)
  end

  def render_km_challenge_total_support(nil, _), do: 0

  def render_km_challenge_total_support(
        %Decimal{} = total_km_pledges,
        distance_target
      ) do
        Decimal.mult(total_km_pledges, distance_target)
        |> Decimal.round(1)
        |> Decimal.to_string()
      end

  def render_current_pledges(nil, _), do: 0

  def render_current_pledges(%Decimal{} = total_pledges, distance),
    do: Decimal.mult(total_pledges, distance) |> Decimal.to_string()

  def total_pledges(nil, _), do: 0

  def total_pledges(%Decimal{} = total_pledges, distance),
    do: Decimal.mult(total_pledges, distance) |> Decimal.to_integer()
end
