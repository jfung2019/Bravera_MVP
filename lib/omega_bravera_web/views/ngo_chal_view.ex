defmodule OmegaBraveraWeb.NGOChalView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Challenges.NGOChal, Trackers.Strava, Accounts.User}

  def user_full_name(%User{} = user), do: User.full_name(user)

  def user_profile_pic(%Strava{athlete_id: athlete_id}) do
    "https://www.strava.com/athletes/#{Integer.to_string(athlete_id)}/avatar?size=large"
  end

  def user_profile_pic(nil), do: ""

  def active_challenge?(%NGOChal{status: "active"}), do: true
  def active_challenge?(%NGOChal{}), do: false

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
  def render_percentage(target, current, 0), do: (current / target) * 100
  def render_percentage(target, current, _previous) when current >= target, do: 100
  def render_percentage(target, current, previous) when previous > 0 do
    ((current - previous) / target) * 100
    |> Float.round(2)
  end


  def render_progress_bar(target, previous_target, %{default_currency: currency, distance_covered: distance}, total) do
    percentage = render_percentage(target, distance, previous_target)
    {label_class, total_class} =
      if percentage >= 100 do
        {"text-bravera text-500", "float-right text-success"}
      else
        {"milestone-label", "float-right"}
      end
      [content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1", style: "text-align: left;") do
        [content_tag(:span, "#{target}km", class: label_class),
        content_tag(:span, class: "text-secondary") do
          content_tag(:strong, "#{currency_to_symbol(currency)}#{total || 0}", class: total_class)
        end]
      end,
      content_tag(:div, "", style: "clear: both;"),
      content_tag(:div, class: "progress chal-progress mb-2") do
        content_tag(:div, "", class: "progress-bar bg-bravera", style: "width: #{percentage}%", role: "progressbar", "aria-valuenow": "", "aria-valuemin": "0", "aria-valuemax": "")
      end]
    end

  def render_total_pledged(pending, secured, default_currency) do
    color =
      if pending <= secured and pending != 0 do
        "text-success"
      else
        "text-secondary"
      end

    content_tag(:h5, class: "text-420 mt-2 mb-1 ml-1 text-left #{color}") do
      ["Total Pledged:",
        content_tag(:span, class: "float-right") do
          content_tag(:strong,"#{currency_to_symbol(default_currency) <> Integer.to_string(pending)}")
        end]
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
    ["Total Secured:",
      content_tag(:span, class: "float-right") do
        content_tag(:strong,"#{currency_to_symbol(default_currency) <> Integer.to_string(secured)}")
      end]
    end
  end
end
