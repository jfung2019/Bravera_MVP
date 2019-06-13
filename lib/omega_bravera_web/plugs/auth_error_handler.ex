defmodule OmegaBravera.AuthErrorHandler do
  alias OmegaBravera.Guardian
  require Logger

  # TODO handle this properly
  def auth_error(conn, {:invalid_token, _reason} = error_tuple, _opts) do
    Logger.warn("AUTH_ERROR CALLBACK: #{inspect(error_tuple)}")
    conn
    |> Guardian.Plug.sign_out()
  end

  def auth_error(conn, {_type, _reason} = error_tuple, _opts) do
    Logger.warn("AUTH_ERROR CALLBACK: #{inspect(error_tuple)}")
    conn
  end
end
