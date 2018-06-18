defmodule OmegaBravera.AuthErrorHandler do
  import Plug.Conn

  # TODO This is a JSON 401, we need an HTML 401...
  def auth_error(conn, {type, _reason}, _opts) do
    body = Poison.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
