defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def new(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %Accounts.PartnerUser{} ->
        redirect(conn, to: Routes.org_panel_dashboard_path(conn, :index))

      _ ->
        render(conn, "new.html", changeset: Accounts.change_partner_user(%Accounts.PartnerUser{}))
    end
  end

  def create(conn, %{"partner_user" => register_params}) do
    %{"business_type" => business_type} = register_params
    case Accounts.create_partner_user_and_organization(business_type, register_params) do
      {:ok, %{create_partner_user: partner_user}} ->
        OmegaBravera.Accounts.Notifier.partner_user_signup_email(partner_user)

        conn
        |> put_flash(:info, "Account created! Please check your inbox and click the link we sent to verify your account email.")
        |> redirect(to: Routes.partner_user_register_path(conn, :new))

      {:error, :create_partner_user, changeset, _} ->
        conn
        |> put_flash(:error, "Error Registering.")
        |> render("new.html", changeset: changeset)
    end
  end
end
