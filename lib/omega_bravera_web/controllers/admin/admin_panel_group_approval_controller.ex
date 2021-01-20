defmodule OmegaBraveraWeb.AdminPanelGroupApprovalController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Groups, Groups.GroupApproval}

  def show(conn, %{"id" => id}) do
    render(conn, "show.html",
      group: Groups.get_partner!(id),
      changeset: Groups.change_group_approval(%GroupApproval{})
    )
  end

  def create(conn, %{"group_approval" => %{"group_id" => id} = approval_param}) do
    case Groups.create_group_approval(approval_param) do
      {:ok, %{changes: %{status: status}}} ->
        conn
        |> put_flash(:info, "Group #{status}.")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :index))

      {:error, changeset} ->
        render(conn, "show.html", group: Groups.get_partner!(id), changeset: changeset)
    end
  end
end
