defmodule OmegaBraveraWeb.StravaController do
  use OmegaBraveraWeb, :controller
  require Logger

  alias OmegaBravera.{Guardian, Challenges, Accounts, Money, StripeHelpers}

  # TODO Check if activity was manual update or GPS upload
  # Is upload_id only for file uploads?
  # upload_id: 123123123121
  #
  # Is created_at nil only for file updates or also for third-party trackers?
  # created_at: nil

  def post_webhook_callback(conn, params) do
    Logger.info fn ->
      "Strava Webhook received: #{inspect(params)}"
    end

    %{"aspect_type" => aspect_type, "object_type" => object_type} = params
    # TODO Logic for deletion
    # TODO Logic for removing activities
    # TODO Logic for updating activities

    cond do
      object_type == "activity" ->
        cond do
          aspect_type == "create" ->
            get_new_activity(params)
        end
    end

    conn |> render("webhook_callback.json", status: "200")
  end

# TODO Add guards for starting date
  def get_new_activity(params) do
    %{"object_id" => object_id, "owner_id" => owner_id} = params

    relevant_challengers = Accounts.get_strava_challengers(owner_id)

    cond do
      relevant_challengers != [] ->
        # TODO optimize this access call
        {_, token} = get_in(relevant_challengers, [Access.at(0)])

        client = Strava.Client.new(token)
        # TODO %{"distance" => distance}
        activity = Strava.Activity.retrieve(object_id, client)

        Logger.info fn ->
          "STRAVA ACTIVITY RECEIVED: #{inspect(activity)}"
        end

        if activity.distance > 0.0 do
          distance_meters = Decimal.new(activity.distance)

          d_thousand = Decimal.new(1000)

          distance_km = Decimal.div(distance_meters, d_thousand)

          Enum.each(relevant_challengers, fn {id, _token} ->
            ngo_chal = Challenges.get_ngo_chal!(id)

            %{id: nc_id,
            distance_covered: nc_distance_covered,
            distance_target: nc_distance_target,
            milestones: milestone_count
            } = ngo_chal

            # TODO abstract this milestone distance bit out since it is used multiple times
            # TODO round properly

            milestone_distance = Numbers.div(nc_distance_target, milestone_count)

            new_distance = Decimal.add(nc_distance_covered, distance_km)

            # TODO evaluate Rounding in this less than/greater than nested conditional,
            # milestones may be charged prematurely due to rounding upwards?
            cond do
              Decimal.cmp(new_distance, nc_distance_target) == :lt ->
                Challenges.update_ngo_chal(ngo_chal, %{distance_covered: new_distance})
                cond do
                  Decimal.cmp(new_distance, milestone_distance) == :gt || Decimal.cmp(new_distance, milestone_distance) == :eq ->
                    # TODO Will rounding here ever round up? Should always round to floor?
                    d_milestones_completed = Decimal.round(Decimal.div(new_distance, milestone_distance))

                    milestones_completed = Decimal.to_integer(d_milestones_completed)

                    IO.inspect("milestones completed")
                    IO.inspect(milestones_completed)

                    # TODO charge uncharged milestones

                    donations_to_charge = Money.get_donations_by_milestone(nc_id, milestones_completed)

                    StripeHelpers.charge_multiple_donations(donations_to_charge)

                    # TODO email the donors on charge in charge function a single email?
                  true ->
                    # todo get rid of this IO
                    IO.inspect("no new milestones unlocked")
                end

                # TODO email everyone
              true ->

                Challenges.update_ngo_chal(ngo_chal, %{distance_covered: nc_distance_target, status: "Complete"})

                # TODO email everyone
            end

          end)
        end
      true ->
        Logger.info fn ->
          "Strava Webhook received, no active challenger found matching Strava ID #{owner_id}, for Activity ID: #{object_id}"
        end
    end
  end

  def get_webhook_callback(conn, params) do
    %{"hub.challenge" => hub_challenge} = params

    conn |> render("hub_challenge.json", hub_challenge: hub_challenge)
  end

  def authenticate(conn, _params) do
    redirect conn, external: Strava.Auth.authorize_url!(scope: "view_private")
  end

  @doc """
  This action is reached via `/auth/callback` and is the the callback URL that Strava will redirect the user back to with a `code` that will be used to request an access token.
  The access token will then be used to access protected resources on behalf of the user.
  """

  # Make separate Strava params for a Strava record, create email if email doesn't exist?

  # Would have to make function to check if user is logged in already to add Strava to fitness provider

  def strava_callback(conn, %{"code" => code}) do
    client = Strava.Auth.get_token!(code: code)
    athlete = Strava.Auth.get_athlete!(client)

    %{token: %{access_token: access_token}} = client

    %{email: athlete_email, firstname: athlete_firstname, lastname: athlete_lastname, id: athlete_id_int} = athlete

    athlete_id = to_string(athlete_id_int)

    params = %{token: access_token, email: athlete_email, firstname: athlete_firstname, lastname: athlete_lastname, athlete_id: athlete_id}

    conn
      |> login(params)
      |> redirect(to: "/")
  end

# have to do a case to handle user connecting strava

  defp login(conn, changeset) do
    case Accounts.insert_or_update_strava_user(changeset) do
      {:ok, result} ->
        # NOTE what does match? do and is it optimal?
        cond do
        match?(%{id: _}, result) ->
          conn
          |> put_flash(:info, "Welcome!")
          |> Guardian.Plug.sign_in(result)
        match?(%{strava: _}, result) ->
          %{user: result_user} = result

          conn
          |> put_flash(:info, "Welcome!")
          |> Guardian.Plug.sign_in(result_user)
        end
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error signing in")
    end
  end

  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end
end
