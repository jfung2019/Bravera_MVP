defmodule OmegaBraveraWeb.AdminPanelPointsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Points, Accounts}

  def new(conn, _) do
    users = Accounts.list_users()
    changeset = Points.change_point(%Points.Point{})
    render(conn, "new.html", changeset: changeset, users: users)
  end

  def create(conn, %{"point" => points_params}) do
    case Points.create_bonus_points(Map.put(points_params, "source", :admin)) do
      {:ok, _point} ->
        conn
        |> put_flash(:info, "Successfully created point!")
        |> redirect(to: Routes.admin_user_page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users()

        conn
        |> render("new.html", changeset: changeset, users: users)
    end
  end
end
