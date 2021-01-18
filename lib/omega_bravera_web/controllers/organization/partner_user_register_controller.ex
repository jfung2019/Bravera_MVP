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

  def create(conn, %{
        "organization_member" => %{
          "organization" => org_params,
          "partner_user" => register_params
        }
      }) do
    case Accounts.create_partner_user_and_organization(org_params, register_params) do
      {:ok, %{create_partner_user: partner_user}} ->
        OmegaBravera.Accounts.Notifier.partner_user_signup_email(partner_user)

        conn
        |> put_flash(
          :info,
          "Account created! Please check your inbox and click the link we sent to verify your account email."
        )
        |> redirect(to: Routes.partner_user_register_path(conn, :new))

      {:error, :create_partner_user, _changeset, _} ->
        org_member_changeset = Accounts.change_organization_member(%Accounts.OrganizationMember{})
        error_register(conn, org_member_changeset)

      {:error, :create_organization, _changeset, _} ->
        org_member_changeset = Accounts.change_organization_member(%Accounts.OrganizationMember{})
        error_register(conn, org_member_changeset)

      {:error, :create_organization_member, changeset, _} ->
        error_register(conn, changeset)
    end
  end

  def error_register(conn, changeset) do
    conn
    |> put_flash(:error, "Error Registering.")
    |> render("new.html", changeset: changeset)
  end
end
