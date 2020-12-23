defmodule OmegaBraveraWeb.PartnerUserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def new(conn, _params), do: render(conn, "new.html")

  def create(conn, %{"username" => username, "password" => password}) do
    case Accounts.partner_user_auth(username, password) do
      {:ok, partner_user} ->
        cond do
          partner_user.email_verified ->
            conn
            |> Guardian.Plug.sign_in(partner_user)
            |> redirect(to: Routes.kaffy_home_path(conn, :index))

          true ->
            conn
            |> put_flash(
              :error,
              gettext("Email not yet verified. Please check your email for a verification link")
            )
            |> render("new.html")
        end

      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Error: Username and/or password incorrect"))
        |> render("new.html")
    end
  end

  def delete(conn, _param) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: Routes.partner_user_session_path(conn, :new))
  end

  def activate_email(conn, %{"email_activation_token" => email_activation_token} = _params) do
    case Accounts.get_partner_user_by_email_activation_token(email_activation_token) do
      {:error, :no_such_user} ->
        conn
        |> put_flash(:error, "No such user.")
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:ok, partner_user} ->
        case Accounts.verify_partner_user_email(partner_user) do
          {:ok, _partner_user} ->
            conn
            |> put_flash(:info, "Email verified.")
            |> redirect(to: Routes.partner_user_session_path(conn, :new))

          {:error, _error} ->
            conn
            |> put_flash(:error, "Failed to verify email.")
            |> redirect(to: Routes.partner_user_session_path(conn, :new))
        end
    end
  end
end
