defmodule OmegaBravera.Accounts.SignupsTrackingWorker do
  import Ecto.Query, only: [from: 2]

  alias OmegaBravera.Accounts.{User, Notifier}
  alias OmegaBravera.Repo

  def process_signups() do
    new_users = Repo.all(new_users_query)
    csv = to_csv(new_users)
    result = Notifier.send_signups_digest(%{users_count: length(new_users), csv: csv})

    {result, new_users, csv}
  end

  defp new_users_query() do
    from(user in User, where: user.inserted_at >= ^start_date and user.inserted_at < ^end_date, preload: [:strava])
  end

  defp start_date() do
    Timex.today()
    |> Timex.shift(days: -1)
    |> Timex.to_datetime()
  end

  defp end_date() do
    Timex.today()
    |> Timex.to_datetime()
  end

  defp to_csv(users) do
    users
    |> Enum.map(&serialize_user/1)
    |> CSV.encode(headers: [:firstname, :lastname, :email, :strava_id, :sex, :location])
    |> Enum.take(length(users) + 1) #forcing the stream to be processed
    |> Enum.join("")
  end

  defp serialize_user(%User{} = user) do
    user
    |> Map.take([:firstname, :lastname, :email])
    |> Map.put(:strava_id, "#{user.strava.athlete_id} (https://www.strava.com/athletes/#{user.strava.athlete_id})")
    |> Map.put(:sex, user_sex(user))
    |> Map.put(:location, user_location(user))
  end

  defp user_sex(%User{additional_info: info}), do: Map.get(info || %{}, "sex", "Not specified") 
  defp user_location(%User{additional_info: info}) do
    case Map.get(info || %{}, "location") do
      "//" -> "Not specified"
      location -> location
    end
  end
end
