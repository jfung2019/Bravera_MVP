defmodule OmegaBraveraWeb.Api.Resolvers.Activity do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Activity.Activities
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def create(_root, %{input: activity_params}, %{
        context: %{current_user: %{id: user_id}, device: %{id: device_id}}
      })
      when not is_nil(device_id) do
    # Get the number of activities at specific time.
    number_of_activities_at_time =
      Activities.get_user_activities_at_time(activity_params, user_id, device_id)

    case Activities.create_app_activity(
           activity_params,
           user_id,
           device_id,
           number_of_activities_at_time
         ) do
      {:ok, activity} ->
        {:ok, %{activity: activity}}

      {:error, changeset} ->
        {:error,
         message: "Could not create activity", details: Helpers.transform_errors(changeset)}
    end
  end

  def create(_root, _params, _info),
    do: {:error, message: gettext("Device token expired or non-existent")}
end
