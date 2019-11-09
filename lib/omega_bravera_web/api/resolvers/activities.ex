defmodule OmegaBraveraWeb.Api.Resolvers.Activity do
  import OmegaBraveraWeb.Gettext
  require Logger

  alias OmegaBravera.Activity.Queue
  alias OmegaBravera.Offers.OfferAppActivitiesIngestion
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def create(_root, %{input: activity_params}, %{
        context: %{current_user: %{id: _user_id} = current_user, device: %{id: device_id}}
      })
      when not is_nil(device_id) do
    create_params = %{
      activity_params: activity_params,
      user: current_user,
      device_id: device_id
    }

    server_name = Queue.generate_server_name(current_user)

    result =
      case Queue.start_link([create_params], server_name) do
        {:ok, _} ->
          Logger.info("API: Started Queue successfully..")
          Queue.dequeue(server_name)

        {:error, {:already_started, _}} ->
          Logger.info("API: Queue already started, adding activity..")
          Queue.enqueue(server_name, create_params)
          Queue.dequeue(server_name)
      end

    case result do
      {:ok, activity} ->
        OfferAppActivitiesIngestion.start(activity)
        {:ok, %{activity: activity}}

      {:error, changeset} ->
        {:error,
         message: "Could not create activity", details: Helpers.transform_errors(changeset)}
    end
  end

  def create(_root, _params, _info),
    do: {:error, message: gettext("Device token expired or non-existent")}
end
