defmodule OmegaBraveraWeb.OrgPanelPointsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Points, Accounts}

  def new(%{assigns: %{organization_id: org_id}} = conn, _) do
    users = Accounts.list_users_for_org(org_id)
    changeset = Points.change_point(%Points.Point{})
    remaining_points = Accounts.get_remaining_points_for_today_for_organization(org_id)

    render(conn, "new.html",
      changeset: changeset,
      users: users,
      remaining_points: remaining_points
    )
  end

  def create(%{assigns: %{organization_id: org_id}} = conn, %{"point" => points_params}) do
    case Points.add_organization_points(org_id, points_params) do
      {:ok, _point} ->
        conn
        |> put_flash(:info, "Points update successful. The team member will be notified.")
        |> redirect(to: Routes.org_panel_points_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users_for_org(org_id)
        remaining_points = Accounts.get_remaining_points_for_today_for_organization(org_id)

        conn
        |> render("new.html",
          changeset: changeset,
          users: users,
          remaining_points: remaining_points
        )
    end
  end
end
