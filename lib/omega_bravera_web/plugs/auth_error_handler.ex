defmodule OmegaBravera.AuthErrorHandler do
  alias OmegaBravera.Guardian
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  require Logger

  def auth_error(%{request_path: path} = conn, {:invalid_token, :token_expired}, _opts) do
    conn
    |> Guardian.Plug.sign_out()
    |> Plug.Conn.put_session("after_login_redirect", path)
    |> redirect(to: "/login")
  end

  # TODO handle this properly
  def auth_error(conn, {_type, _reason} = error_tuple, _opts) do
    Logger.warn("AUTH_ERROR CALLBACK: #{inspect(error_tuple)}")

    conn
    |> put_flash(:info, "Please login")
    |> redirect(to: "/login")
  end
end
