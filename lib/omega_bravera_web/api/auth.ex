defmodule OmegaBraveraWeb.Api.Auth do
  @salt "AK123p9i#!AASDAIJSDIAJ@##!!!@22310"
  @context OmegaBraveraWeb.Endpoint

  def generate_device_token(device_uuid),
    do: Phoenix.Token.sign(@context, @salt, {:device_uuid, device_uuid})

  def decrypt_token(token), do: Phoenix.Token.verify(@context, @salt, token, max_age: 86400)
end
