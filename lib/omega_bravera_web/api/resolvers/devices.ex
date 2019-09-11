defmodule OmegaBraveraWeb.Api.Resolvers.Devices do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Devices
  alias OmegaBraveraWeb.Api.Resolvers.Helpers
  alias OmegaBraveraWeb.Api.Auth

  def register_device(_root, %{input: %{active: active, uuid: uuid}}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Devices.create_device(%{active: active, uuid: uuid, user_id: user_id}) do
      {:ok, %{create_device: device}} ->
        {:ok,
         %{
           token: Auth.generate_device_token(device.uuid),
           expires_at: Timex.shift(Timex.now(), days: 1)
         }}

      {:error, :create_device, changeset, _changes} ->
        {:error,
         message: gettext("Could not create device"), details: Helpers.transform_errors(changeset)}
    end
  end

  def refresh_device_token(_root, %{input: %{uuid: uuid}}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Devices.get_device_by_uuid(uuid, user_id) do
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
end
