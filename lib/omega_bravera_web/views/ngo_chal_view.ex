defmodule OmegaBraveraWeb.NGOChalView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Challenges.NGOChal, Trackers.Strava, Accounts.User}

  def user_full_name(%User{} = user), do: User.full_name(user)

  def user_profile_pic(%Strava{} = strava) do
    "https://www.strava.com/athletes/#{Integer.to_string(strava.athlete_id)}/avatar?size=large"
  end

  def active_challenge?(%NGOChal{} = challenge) do
    challenge.status == "active"
  end
end
