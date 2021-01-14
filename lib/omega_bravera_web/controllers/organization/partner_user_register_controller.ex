defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def new(conn, _params),
    do: render(conn, "new.html", changeset: Accounts.change_partner_user(%Accounts.PartnerUser{}))

  def create(conn, %{"partner_user" => register_params}) do
    case Accounts.create_partner_user_and_organization(register_params) do
      {:ok, %{create_partner_user: partner_user}} ->
        OmegaBravera.Accounts.Notifier.partner_user_signup_email(partner_user)

        conn
        |> put_flash(:info, "Account created. Please go to your email to verify the account.")
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:error, :create_partner_user, changeset, _} ->
        conn
        |> put_flash(:error, "Error Registering.")
        |> render("new.html", changeset: changeset)
    end
  end
end
