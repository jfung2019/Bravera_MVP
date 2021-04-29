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

  def view_as(conn, %{"id" => "remove"}) do
    conn = Plug.Conn.delete_session(conn, :view_as_org_id)
    redirect(conn, to: Routes.admin_panel_organization_path(conn, :index))
  end

  def view_as(conn, %{"id" => id}) do
    conn = Plug.Conn.put_session(conn, :view_as_org_id, id)
    redirect(conn, to: Routes.admin_panel_partner_path(conn, :index))
  end
end
