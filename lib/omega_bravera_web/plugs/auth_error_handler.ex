defmodule OmegaBravera.AuthErrorHandler do
  alias OmegaBravera.Guardian
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  require Logger

  # TODO handle this properly
  def auth_error(conn, {:invalid_token, _reason} = error_tuple, _opts) do
    Logger.warn("AUTH_ERROR CALLBACK: #{inspect(error_tuple)}")
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: "/login")
  end

  def auth_error(conn, {_type, _reason} = error_tuple, _opts) do
    Logger.warn("AUTH_ERROR CALLBACK: #{inspect(error_tuple)}")
    conn
    |> put_flash(:info, "Please login")
    |> redirect(to: "/login")
  end
end
