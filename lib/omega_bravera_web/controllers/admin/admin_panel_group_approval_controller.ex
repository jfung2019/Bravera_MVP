defmodule OmegaBraveraWeb.AdminPanelGroupApprovalController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Groups, Groups.GroupApproval}

  def show(conn, %{"id" => id}) do
    render(conn, "show.html",
      group: Groups.get_partner!(id),
      changeset: Groups.change_group_approval(%GroupApproval{})
    )
  end

  def approve(conn, %{"group_approval" => %{"group_id" => id} = approval_param}) do
    case Groups.create_group_approval(approval_param) do
      {:ok, _} ->
        conn
        |> redirect(to: Routes.admin_panel_partner_path(conn, :index))

      {:error, changeset} ->
        render(conn, "show.html", group: Groups.get_partner!(id), changeset: changeset)
    end
  end
end
