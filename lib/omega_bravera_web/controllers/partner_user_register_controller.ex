defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def new(conn, _params), do: render(conn, "new.html")

  def create(conn, register_params) do
    case Accounts.create_partner_user(register_params) do
      {:ok, partner_user} ->
        OmegaBravera.Accounts.Notifier.partner_user_signup_email(partner_user)
        conn
        |> put_flash(:info, "Account created. Please go to your email to verify the account.")
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:error, _} ->
        conn
        |> put_flash(:error, "Error Registering.")
        |> render("new.html")
    end
  end
end