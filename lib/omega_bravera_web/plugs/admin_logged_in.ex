defmodule OmegaBraveraWeb.AdminLoggedIn do
  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.AdminUser

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        conn

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end

  def login_by_email_and_pass(conn, email, pass) do
    case Accounts.authenticate_admin_user_by_email_and_pass(email, pass) do
      {:ok, user} -> {:ok, user, OmegaBravera.Guardian.Plug.sign_in(conn, user)}
      {:error, :unauthorized} -> {:error, :unauthorized, conn}
      {:error, :not_found} -> {:error, :not_found, conn}
    end
  end
end
