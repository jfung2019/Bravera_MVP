defmodule OmegaBraveraWeb.ViewHelpers do
  alias OmegaBravera.Accounts.User

  def logged_in?(conn) do
    user = Guardian.Plug.current_resource(conn)
    if user !== nil, do: true
  end

  def has_tracker?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %User{strava: strava} when strava != nil ->
        true
      _ ->
        false
    end
  end

  def render_datetime(naive_date_time) do
    with {:ok, date_time} <- DateTime.from_naive(naive_date_time, "Etc/UTC"),
         hk_date_time <- Timex.Timezone.convert(date_time, "Asia/Hong_Kong"),
        {:ok , formatted_string} <- Timex.format(hk_date_time, "{D}/{M}/{WYY} {h24}:{m}") do
      formatted_string
    end
  end

end
