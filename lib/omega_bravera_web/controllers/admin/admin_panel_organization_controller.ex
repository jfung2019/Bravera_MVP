defmodule OmegaBraveraWeb.AdminPanelOrganizationController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.Organization

  def index(conn, params) do
    results =
      Turbo.Ecto.turbo(Accounts.list_organization_with_member_count_query(), params,
        entry_name: "organizations"
      )

    render(conn, "index.html", organizations: results.organizations, paginate: results.paginate)
  end

  def new(conn, _params) do
    changeset = Accounts.change_organization(%Organization{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"organization" => organization_params}) do
    case Accounts.create_organization(organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization created successfully.")
        |> redirect(to: Routes.admin_panel_organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Accounts.get_organization!(id)
    render(conn, "show.html", organization: organization)
  end

  def edit(conn, %{"id" => id}) do
    organization = Accounts.get_organization!(id)
    changeset = Accounts.change_organization(organization)
    render(conn, "edit.html", organization: organization, changeset: changeset)
  end

  def update(conn, %{"id" => id, "organization" => organization_params}) do
    organization = Accounts.get_organization!(id)

    case Accounts.update_organization(organization, organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization updated successfully.")
        |> redirect(to: Routes.admin_panel_organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", organization: organization, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Accounts.get_organization!(id)
    {:ok, _organization} = Accounts.delete_organization(organization)

    conn
    |> put_flash(:info, "Organization deleted successfully.")
    |> redirect(to: Routes.admin_panel_organization_path(conn, :index))
  end

  def view_as(conn, %{"id" => id}) do
    with %{id: admin_id} <- OmegaBravera.Guardian.Plug.current_resource(conn),
         partner_user <- Accounts.get_partner_user_by_org_id(id),
         false <- is_nil(partner_user),
         conn <- Plug.Conn.put_session(conn, :admin_logged_in, admin_id) do
      conn
      |> OmegaBravera.Guardian.Plug.sign_in(partner_user)
      |> redirect(to: Routes.org_panel_dashboard_path(conn, :index))
    else
      _ -> redirect(conn, to: Routes.admin_panel_organization_path(conn, :index))
    end
  end

  def block(conn, %{"id" => id}) do
    organization = Accounts.get_organization!(id)
    {:ok, _org} = Accounts.block_or_unblock_org(organization)

    mes = if is_nil(organization.blocked_on), do: "blocked", else: "unblocked"

    conn
    |> put_flash(:info, "Users associated to #{organization.name} is now #{mes}.")
    |> redirect(to: Routes.admin_panel_organization_path(conn, :index))
  end
end
