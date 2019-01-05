defmodule OmegaBraveraWeb.AdminPanelActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges.{Activity, NGOChal, ActivitiesIngestion}
  alias OmegaBravera.{Challenges, Activities, Fundraisers, Repo}

  plug(:assign_available_options when action in [:create, :new])

  def index(conn, _) do
    activities = Activities.list_activities_added_by_admin()
    render(conn, "index.html", activities: activities)
  end

  def new(conn, _) do
    current_admin_user = Guardian.Plug.current_resource(conn)
    changeset = Activity.create_activity_by_admin_changeset(%Strava.Activity{}, %NGOChal{}, current_admin_user.id)
    challenges = Challenges.list_active_ngo_chals([:user])

    render(conn, "new_activity.html", changeset: changeset, challenges: challenges)
  end

  def create(conn, %{"activity" => activity_params, "challenge_id" => challenge_id}) do
    current_admin_user = Guardian.Plug.current_resource(conn)
    challenge = Challenges.get_ngo_chal!(challenge_id) |> Repo.preload(:user)
    challenges = Challenges.list_active_ngo_chals([:user])
    activity = create_strava_activity(activity_params, current_admin_user, challenge.user)


    changeset = Activity.create_activity_by_admin_changeset(
      activity, challenge, current_admin_user.id
    )

    case changeset.valid? do
      true ->
        case ActivitiesIngestion.process_challenge(challenge, activity) do
          {:ok, :challenge_updated} ->
            conn
            |> put_flash(:info, "Activity created successfully.")
            |> redirect(to: admin_panel_activity_path(conn, :index))
          {:error, :activity_not_processed} ->
            conn
            |> put_flash(:error, "Activity not processed. Please check the logs.")
            |> redirect(to: admin_panel_activity_path(conn, :index))
        end
      false ->
        changeset =
          changeset
          |> Ecto.Changeset.change(
            %{
              moving_time: from_seconds_to_time_map(activity.moving_time),
              start_date: to_hk(activity.start_date)
            })
        conn
        |> render("new_activity.html", changeset: changeset, challenges: challenges)
    end
  end

  def import_activity_from_strava(conn, _) do
    # Not Implemented
  end

  defp create_strava_activity(params, current_admin_user, participant) do
    activity_params = params |> map_keys_to_atoms()

    Strava.Activity
    |> struct(activity_params)
    |> Map.put(:start_date, to_utc(activity_params.start_date))
    |> Map.put(:distance, from_string_to_float(activity_params.distance))
    |> Map.put(:moving_time, from_time_to_seconds(activity_params.moving_time))
    |> Map.put(:manual, false)
    |> Map.put_new(:admin_id, current_admin_user.id)
    |> add_average_speed(activity_params)
    |> add_calories(activity_params, participant)
  end

  defp map_keys_to_atoms(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end

  defp to_utc(datetime_map) do
    {:ok, datetime} = Ecto.DateTime.cast(datetime_map)

    datetime
    |> Timex.to_datetime()
    |> DateTime.to_naive()
    |> Timex.to_datetime("Asia/Hong_Kong")
    |> Timex.to_datetime("Etc/UTC")
  end

  defp to_hk(datetime) do
    datetime
    |> DateTime.to_naive()
    |> Timex.to_datetime("Etc/UTC")
    |> Timex.to_datetime("Asia/Hong_Kong")
  end

  defp from_string_to_float(""), do: nil
  defp from_string_to_float(string), do: Decimal.new(string)

  defp from_string_to_integer(""), do: 0
  defp from_string_to_integer(string) do
   {integer, _} = Integer.parse(string)
   integer
  end

  defp from_time_to_seconds(time_map),
   do: (from_string_to_integer(time_map["hour"]) * 3600) + (from_string_to_integer(time_map["minute"]) * 60)

  defp from_seconds_to_time_map(seconds) do
    {hour, minute} = Decimal.div_rem( Decimal.div(seconds, Decimal.new(60)), Decimal.new(60))

    %{
      "hour" => Decimal.to_string(hour),
      "minute" => Decimal.to_string(minute)
    }
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_activities, Fundraisers.available_activities())
  end

  defp add_average_speed(%Strava.Activity{} = activity, activity_params) do
    activity = Map.put(activity, :average_speed, from_string_to_float(activity_params.average_speed))

    if activity.average_speed == nil do
      # distance in meters / time in seconds = average km per hour
      average_speed =
        activity.distance
        |> Decimal.mult(Decimal.new(1000))
        |> Decimal.div(Decimal.new(activity.moving_time))
        |> Decimal.round(1)

      %{activity | average_speed:  average_speed}
    else
      activity
    end
  end

  defp add_calories(%Strava.Activity{} = activity, activity_params, participant) do
    participant = participant |> Repo.preload(:strava)
    activity = Map.put(activity, :calories, from_string_to_float(activity_params.calories))
    athlete = Strava.Athlete.retrieve(
      participant.strava.athlete_id,
      Strava.Client.new(participant.strava.token)
    )

    # Metabolic equivalent
    met_values = %{
      "Run" => Decimal.new(13.0),
      "Cycle" => Decimal.new(4.5),
      "Walk" => Decimal.new(2.9),
      "Hike" => Decimal.new(7.0)
    }

    # Calculate calories based on MET value and Weight and Duration.
    if activity.calories == nil do
      # calories per hour = met_value * weight in kg
      calories_per_hour =
        if athlete.weight != nil do
          Decimal.new(athlete.weight)
          |> Decimal.mult(met_values[activity.type])
          |> Decimal.round(1)
        else
          Decimal.new(0)
        end

      # calories = calories per hour * (duration in minutes / 60)
      duration_in_minutes = Decimal.div(activity.moving_time, Decimal.new(60))
      duration_in_hours = Decimal.div(duration_in_minutes, Decimal.new(60))
      calories = Decimal.mult(calories_per_hour, duration_in_hours) |> Decimal.round()

      %{activity | calories:  calories}
    else
      activity
    end

  end
end
