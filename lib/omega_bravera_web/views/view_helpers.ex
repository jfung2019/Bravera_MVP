defmodule OmegaBraveraWeb.ViewHelpers do
  import Phoenix.HTML.Tag, only: [tag: 2]
  alias OmegaBravera.Accounts.{User, AdminUser, PartnerUser}
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Offers.{Offer, OfferChallenge}

  def logged_in?(conn), do: Guardian.Plug.current_resource(conn) !== nil

  def get_add_team_member_redirect_uri(conn) do
    case Plug.Conn.get_session(conn, "add_team_member_url") do
      nil ->
        nil

      uri ->
        Plug.Conn.delete_session(conn, "add_team_member_url")
        uri
    end
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

  def is_partner_user?(conn) do
    case Guardian.Plug.current_resource(conn) do
      %PartnerUser{} ->
        true

      _ ->
        false
    end
  end

  def is_own_offer_challenge?(%OfferChallenge{user_id: user_id}, %User{id: user_id}),
    do: true

  def is_own_offer_challenge?(_, _), do: false

  def is_own_challenge?(%NGOChal{user_id: user_id}, %User{id: user_id}), do: true
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

  def redeemed_date(redeem) do
    if redeem.status == "redeemed" do
      render_datetime(redeem.updated_at)
    else
      "-"
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

  @doc """
  Return one profile picture.

  Priority is:
  Bravera profile picture
  Tracker profile picture
  Default profile picture.
  """
  def profile_picture_or_default(
        %User{profile_picture: bravera_pp, strava: nil},
        default
      ) do
    cond do
      valid_uri?(bravera_pp) -> bravera_pp
      true -> default
    end
  end

  def profile_picture_or_default(
        %User{profile_picture: bravera_pp, strava: %{strava_profile_picture: strava_pp}},
        default
      ) do
    cond do
      valid_uri?(bravera_pp) -> bravera_pp
      valid_uri?(strava_pp) -> strava_pp
      true -> default
    end
  end

  def profile_picture_or_default(%Ecto.Association.NotLoaded{}, default), do: default

  defp valid_uri?(nil), do: false

  defp valid_uri?(str) do
    uri = URI.parse(str)

    case uri do
      %URI{scheme: nil} -> false
      %URI{host: nil} -> false
      %URI{path: nil} -> false
      _ -> true
    end
  end

  def currency_to_symbol(currency) do
    case String.downcase(currency) do
      "myr" -> "RM"
      "hkd" -> "HK$"
      "krw" -> "₩"
      "sgd" -> "S$"
      "gbp" -> "£"
      _ -> "$"
    end
  end

  @doc """
  Returns class if in same section for the current URL path
  """
  def in_current_path(conn, path, class \\ "active") do
    if String.starts_with?(conn.request_path, path) do
      class
    else
      ""
    end
  end

  # Do not divide by zero please.
  def render_percentage_exceed(_, 0), do: 0
  def render_percentage_exceed(nil, _), do: 0

  def render_percentage_exceed(total, %Decimal{} = target),
    do: round(total / Decimal.to_integer(target) * 100)

  def render_percentage_exceed(%Decimal{} = total, target),
    do: round((Decimal.round(total) |> Decimal.to_integer()) / target * 100)

  def render_percentage_exceed(total, target),
    do: round(total / target * 100)

  def pre_registration_ngo?(%NGO{open_registration: false} = ngo),
    do: Timex.after?(ngo.launch_date, Timex.now())

  def pre_registration_ngo?(%NGO{}), do: false

  def pre_registration_offer?(%Offer{open_registration: false, end_date: end_date}),
    do: Timex.after?(end_date, Timex.now())

  def pre_registration_offer?(%Offer{}), do: false

  def number_with_commas(number) when is_integer(number),
    do: Number.Delimit.number_to_delimited(number, precision: 0)

  def number_with_commas(number), do: Number.Delimit.number_to_delimited(number)
end
