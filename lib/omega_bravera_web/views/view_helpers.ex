defmodule OmegaBraveraWeb.ViewHelpers do
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Accounts.AdminUser

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

  def is_admin?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        true

      _ ->
        false
    end
  end

  def render_datetime(naive_date_time) do
    IO.inspect "Printing statement troublesome date: #{naive_date_time}"
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
    {:ok, formatted_date_time} =
      date_time
      |> Timex.format("{D}/{M}/{WYYYY}")
    formatted_date_time
  end

  def render_activity(nil), do: 0
  def render_activity(%Decimal{} = activity), do: Decimal.round(activity, 1)
end
