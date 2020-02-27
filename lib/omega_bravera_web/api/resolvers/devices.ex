defmodule OmegaBraveraWeb.Api.Resolvers.Devices do
  require Logger

  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Devices
  alias OmegaBraveraWeb.Api.Resolvers.Helpers
  alias OmegaBraveraWeb.Api.Auth
  alias OmegaBravera.Activity.Activities

  def register_device(_root, %{input: %{active: active, uuid: uuid}}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    # TODO: BUG: update or create instead of create since a user can get back to an inactive device.
    case Devices.create_device(%{active: active, uuid: uuid, user_id: user_id}) do
      {:ok, %{create_or_update_device: device}} ->
        {:ok,
         %{
           token: Auth.generate_device_token(device.uuid),
           expires_at: Timex.shift(Timex.now(), days: 1)
         }}

      {:error, :create_or_update_device, changeset, _changes} ->
        Logger.info("Could not register device, reason: #{inspect(changeset)}")

        {:error,
         message: gettext("Could not create device"), details: Helpers.transform_errors(changeset)}
    end
  end

  def refresh_device_token(_root, _input, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Devices.get_active_device_by_user_id(user_id) do
      nil ->
        {:error, "Device not registered."}

      device ->
        {:ok,
         %{
           token: Auth.generate_device_token(device.uuid),
           expires_at: Timex.shift(Timex.now(), days: 1)
         }}
    end
  end

  def get_latest_sync_time(_root, _input, %{
        context: %{
          current_user: %{id: user_id},
          device: %{id: _device_id, inserted_at: inserted_at}
        }
      }) do
    case Activities.get_latest_device_activity(user_id) do
      %{end_date: end_date} ->
        {:ok, %{last_sync_at: end_date, utc_now: Timex.now()}}

      nil ->
        {:ok, %{last_sync_at: inserted_at, utc_now: Timex.now()}}
    end
  end
end
