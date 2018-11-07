defmodule OmegaBraveraWeb.UserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def create(conn, %{"session" => %{"email" => email, "password" => pass}}) do
    case Accounts.email_password_auth(email, pass) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: "/")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> redirect(to: page_path(conn, :login))
    end
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end
end
