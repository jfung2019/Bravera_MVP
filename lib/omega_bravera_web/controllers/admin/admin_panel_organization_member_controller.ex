defmodule OmegaBraveraWeb.AdminPanelOrganizationMemberController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.OrganizationMember
  plug :assign_available_options when action in [:new, :edit]

  def index(conn, params) do
    results =
      Turbo.Ecto.turbo(
        Accounts.list_organization_members_with_preloads_query([
          :organization,
          partner_user: :location
        ]),
        params,
        entry_name: "organization_members"
      )

    render(conn, "index.html",
      organization_members: results.organization_members,
      paginate: results.paginate
    )
  end

  def new(conn, _params) do
    changeset = Accounts.change_organization_member(%OrganizationMember{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"organization_member" => organization_member_params}) do
    case Accounts.create_organization_partner_user(organization_member_params) do
      {:ok, organization_member} ->
        conn
        |> put_flash(:info, "Organization member created successfully.")
        |> redirect(
          to: Routes.admin_panel_organization_member_path(conn, :show, organization_member)
        )

      {:error, changeset} ->
        organizations = Accounts.list_organization()

        conn
        |> assign_available_options()
        |> put_flash(:error, "Failed to create partner user.")
        |> render("new.html", changeset: changeset, organizations: organizations)
    end
  end

  def show(conn, %{"id" => id}) do
    organization_member = Accounts.get_organization_member!(id)
    render(conn, "show.html", organization_member: organization_member)
  end

  def edit(conn, %{"id" => id}) do
    organization_member = Accounts.get_organization_member!(id)
    changeset = Accounts.change_organization_member(organization_member)

    render(conn, "edit.html", organization_member: organization_member, changeset: changeset)
  end

  def update(conn, %{"id" => id, "partner_user" => organization_member_params}) do
    organization_member = Accounts.get_organization_member!(id)

    case Accounts.update_organization_partner_user(
           organization_member,
           organization_member_params
         ) do
      {:ok, organization_member} ->
        conn
        |> put_flash(:info, "Organization member updated successfully.")
        |> redirect(
          to: Routes.admin_panel_organization_member_path(conn, :show, organization_member)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_available_options()
        |> render("edit.html", organization_member: organization_member, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization_member = Accounts.get_organization_member!(id)
    partner_user = Accounts.get_partner_user!(organization_member.partner_user_id)
    {:ok, _partner_user} = Accounts.delete_partner_user(partner_user)

    conn
    |> put_flash(:info, "Organization member deleted successfully.")
    |> redirect(to: Routes.admin_panel_organization_member_path(conn, :index))
  end

  defp assign_available_options(conn, _opts \\ nil) do
    conn
    |> assign(:organizations, Accounts.list_organization())
    |> assign(:available_locations, OmegaBravera.Locations.list_locations())
  end
end
