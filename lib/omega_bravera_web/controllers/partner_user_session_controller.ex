defmodule OmegaBraveraWeb.PartnerUserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def new(conn, _params), do: render(conn, "new.html")

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.partner_user_auth(email, password) do
      {:ok, partner_user} ->
        conn
        |> Guardian.Plug.sign_in(partner_user)
        |> redirect(to: Routes.kaffy_home_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Error logging in")
        |> render("new.html")
    end
  end

  def delete(conn, _param) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: Routes.partner_user_session_path(conn, :new))
  end
end
