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
end
