defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def new(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %Accounts.PartnerUser{} ->
        redirect(conn, to: Routes.org_panel_dashboard_path(conn, :index))

      _ ->
        render(conn, "new.html",
          changeset: Accounts.change_organization_member(%Accounts.OrganizationMember{})
        )
    end
  end

  def create(conn, %{"organization_member" => member_params}) do
    case Accounts.create_partner_user_and_organization(member_params) do
      {:ok, %{partner_user: partner_user}} ->
        OmegaBravera.Accounts.Notifier.partner_user_signup_email(partner_user)

        conn
        |> put_flash(
          :info,
          "Account created! Please check your inbox and click the link we sent to verify your account email."
        )
        |> redirect(to: Routes.partner_user_register_path(conn, :new))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error Registering.")
        |> render("new.html", changeset: changeset)
    end
  end
end
