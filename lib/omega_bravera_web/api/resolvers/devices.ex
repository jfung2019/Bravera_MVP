defmodule OmegaBraveraWeb.Api.Resolvers.Devices do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Devices
  alias OmegaBraveraWeb.Api.Resolvers.Helpers
  alias OmegaBraveraWeb.Api.Auth

  def register_device(_root, %{input: %{active: active, uuid: uuid}}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Devices.create_device(%{active: active, uuid: uuid, user_id: user_id}) do
      {:ok, device} ->
        {:ok,
         %{
           token: Auth.generate_device_token(device.uuid),
           expires_at: Timex.shift(Timex.now(), days: 1)
         }}

      {:error, changeset} ->
        {:error,
         message: gettext("Could not create device"), details: Helpers.transform_errors(changeset)}
    end
  end
end
