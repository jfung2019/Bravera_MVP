defmodule OmegaBraveraWeb.AdminPanelOfferChallengeActivityController do
  use OmegaBraveraWeb, :controller

  require Logger

  alias OmegaBravera.Offers.{OfferActivitiesIngestion}
  alias OmegaBravera.{Offers, Repo}
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.ActivityAccumulator

  plug(:assign_available_options when action in [:create, :new])

  def new(conn, _) do
    current_admin_user = Guardian.Plug.current_resource(conn)

    changeset =
      ActivityAccumulator.create_activity_by_admin_changeset(
        %Strava.Activity{},
        %User{},
        current_admin_user.id
      )

    challenges = Offers.list_offer_challenges() |> Repo.preload([:user])

    render(conn, "new.html", changeset: changeset, challenges: challenges)
  end

  def create(conn, %{
        "activity_accumulator" => activity_params,
        "challenge_id" => challenge_id
      }) do
    current_admin_user = Guardian.Plug.current_resource(conn)
    challenge = Offers.get_offer_challenge!(challenge_id) |> Repo.preload(:user)
    activity = create_strava_activity(activity_params, current_admin_user, challenge.user)

    changeset =
      ActivityAccumulator.create_activity_by_admin_changeset(
        activity,
        # TODO get a user struct here to allow team member activity addition by admin. -Sherief
        challenge.user,
        current_admin_user.id
      )

    case Repo.insert(changeset) do
      {:ok, saved_activity} ->
        case OfferActivitiesIngestion.process_challenge(
               challenge,
               saved_activity,
               challenge.user,
               true
             ) do
          {:ok, :challenge_updated} ->
            conn
            |> put_flash(:info, "Activity created successfully.")
            |> redirect(to: admin_panel_offer_path(conn, :index))

          {:error, :activity_not_processed} ->
            Repo.delete(saved_activity)

            conn
            |> put_flash(:error, "Activity not processed. Please check the logs.")
            |> redirect(to: admin_panel_offer_path(conn, :index))
        end

      {:error, reason} ->
        Logger.error(
          "Could not create offer challenge admin activity, reason: #{inspect(reason)}"
        )

        changeset =
          changeset
          |> Ecto.Changeset.change(%{
            moving_time: from_seconds_to_time_map(activity.moving_time),
            start_date: to_hk(activity.start_date)
          })

        challenges = Offers.list_offer_challenges() |> Repo.preload([:user])
        render(conn, "new_activity.html", changeset: changeset, challenges: challenges)
    end
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

  defp to_utc(%{
         "day" => day,
         "hour" => hour,
         "minute" => minute,
         "month" => month,
         "year" => year
       }) do
    {:ok, datetime} =
      NaiveDateTime.new(
        String.to_integer(year),
        String.to_integer(month),
        String.to_integer(day),
        String.to_integer(hour),
        String.to_integer(minute),
        0
      )

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
    do:
      from_string_to_integer(time_map["hour"]) * 3600 +
        from_string_to_integer(time_map["minute"]) * 60 +
        from_string_to_integer(time_map["second"])

  defp from_seconds_to_time_map(seconds) do
    {hour, minute} = Decimal.div_rem(Decimal.div(seconds, Decimal.new(60)), Decimal.new(60))

    %{
      "hour" => Decimal.to_string(hour),
      "minute" => Decimal.to_string(minute)
    }
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_activities, OmegaBravera.Fundraisers.NgoOptions.activity_options())
  end

  defp add_average_speed(%Strava.Activity{} = activity, activity_params) do
    activity =
      Map.put(activity, :average_speed, from_string_to_float(activity_params.average_speed))

    if activity.average_speed == nil do
      distance = Decimal.mult(activity.distance, Decimal.new(1000))

      duration_in_minutes =
        Decimal.new(activity.moving_time)
        |> Decimal.div(60)
        |> Decimal.div(60)

      time = Decimal.mult(duration_in_minutes, 1000)
      # km/h
      average_speed =
        Decimal.div(distance, time)
        |> Decimal.round(2)

      %{activity | average_speed: average_speed}
    else
      activity
    end
  end

  defp add_calories(%Strava.Activity{} = activity, activity_params, participant) do
    participant = participant |> Repo.preload(:strava)
    activity = Map.put(activity, :calories, from_string_to_float(activity_params.calories))

    # Metabolic equivalent
    met_values = %{
      "Run" => Decimal.new(9),
      "Cycle" => Decimal.from_float(4.5),
      "Walk" => Decimal.from_float(2.9),
      "Hike" => Decimal.new(7)
    }

    # Calculate calories based on MET value and Weight and Duration.
    if activity.calories == nil do
      athlete =
        Strava.Athlete.retrieve(
          participant.strava.athlete_id,
          Strava.Client.new(participant.strava.token)
        )

      # calories per hour = met_value * weight in kg
      calories_per_hour =
        if athlete.weight != nil do
          Decimal.from_float(athlete.weight)
          |> Decimal.mult(met_values[activity.type])
          |> Decimal.round(1)
        else
          Decimal.new(0)
        end

      # calories = calories per hour * (duration in minutes / 60)
      duration_in_minutes = Decimal.div(activity.moving_time, Decimal.new(60))
      duration_in_hours = Decimal.div(duration_in_minutes, Decimal.new(60))
      calories = Decimal.mult(calories_per_hour, duration_in_hours) |> Decimal.round()

      %{activity | calories: calories}
    else
      activity
    end
  end
end
