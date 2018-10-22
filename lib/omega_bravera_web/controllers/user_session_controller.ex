defmodule OmegaBraveraWeb.UserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBraveraWeb.BraveraUserLoggedIn


  def create(conn, %{"session" => %{"email" => email, "password" => pass}}) do
    case BraveraUserLoggedIn.login_by_email_and_pass(conn, email, pass) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: "/")

      {:error, _reason, conn} ->
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
