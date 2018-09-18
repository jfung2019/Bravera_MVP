defmodule OmegaBravera.DailyDigest.Serializers.Participant do
  alias OmegaBravera.{Accounts.User, Repo}

  def fields, do: [:firstname, :lastname, :email, :strava_id, :sex, :location]

  def serialize(%User{} = u) do
    user = preload(u)

    user
    |> Map.take([:firstname, :lastname, :email])
    |> Map.put(:strava_id, "#{user.strava.athlete_id} (https://www.strava.com/athletes/#{user.strava.athlete_id})")
    |> Map.put(:sex, user_sex(user))
    |> Map.put(:location, user_location(user))
  end

  defp preload(user) do
    if Ecto.assoc_loaded?(user.strava) do
      user
    else
      Repo.preload(user, [:strava])
    end
  end

  defp user_sex(%User{additional_info: info}) do
    case Map.get(info || %{}, "sex") do
      "F" -> "F"
      "M" -> "M"
      _ -> "Not specified"
    end
  end

  defp user_location(%User{additional_info: info}) do
    case Map.get(info || %{}, "location") do
      "//" -> "Not specified"
      nil -> "Not specified"
      location -> location
    end
  end
end
