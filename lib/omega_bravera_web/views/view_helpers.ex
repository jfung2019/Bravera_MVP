defmodule OmegaBraveraWeb.ViewHelpers do
  import Phoenix.HTML.Tag, only: [tag: 2]
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Accounts.AdminUser
  alias OmegaBravera.Challenges.NGOChal

  def logged_in?(conn) do
    user = Guardian.Plug.current_resource(conn)
    if user !== nil, do: true, else: false
  end

  def has_tracker?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %User{strava: strava} when strava != nil ->
        true

      _ ->
        false
    end
  end

  def is_admin?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        true

      _ ->
        false
    end
  end

  def is_own_challenge?(%NGOChal{} = challenge, %User{} = user), do: challenge.user.id == user.id
  def is_own_challenge?(_, _), do: false

  def render_datetime(nil), do: ""

  def render_datetime(datetime) when is_tuple(datetime) do
    {:ok, formatted_string} =
      Timex.to_datetime(datetime) |> Timex.format("{D}/{M}/{WYY} {h24}:{m}")

    formatted_string
  end

  def render_datetime(naive_date_time) do
    naive_date_time =
      try do
        naive_date_time |> DateTime.to_naive()
      rescue
        _ ->
          naive_date_time
      end

    with {:ok, date_time} <- DateTime.from_naive(naive_date_time, "Etc/UTC"),
         hk_date_time <- Timex.Timezone.convert(date_time, "Asia/Hong_Kong"),
         {:ok, formatted_string} <- Timex.format(hk_date_time, "{D}/{M}/{WYY} {h24}:{m}") do
      formatted_string
    end
  end

  def render_date(date_time) do
    formatted_date_time =
      date_time
      |> Timex.to_datetime()
      |> DateTime.to_iso8601()

    tag(:span, "data-render-date": formatted_date_time)
  end

  def render_activity(nil), do: 0
  def render_activity(%Decimal{} = activity), do: Decimal.round(activity, 1)

  def render_time(nil), do: "00:00:00"

  def render_time(seconds) do
    Time.add(~T[00:00:00], seconds, :second)
    |> Time.truncate(:second)
    |> Time.to_string()
  end

  def render_countdown_date(nil), do: {:safe, ""}

  def render_countdown_date(datetime) do
    formatted_date_time =
      datetime
      |> Timex.to_datetime()
      |> DateTime.to_iso8601()
    tag(:span, "data-render-countdown": formatted_date_time)
  end
end
