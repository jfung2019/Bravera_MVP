defmodule OmegaBraveraWeb.AdminPanelUserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Repo}

  def index(conn, _params) do
    users = Accounts.list_users_for_admin()
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = id |> Accounts.get_user!() |> Repo.preload(:strava)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_attrs}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user_by_admin(user, user_attrs) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.admin_panel_user_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to update user.")
        |> render("edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => user_id}) do
    case Accounts.gdpr_delete_user(user_id) do
      {:ok, _result} ->
        conn
        |> put_flash(:info, "User deleted successfully.")
        |> redirect(to: Routes.admin_panel_user_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, "User not deleted.")
        |> redirect(to: Routes.admin_panel_user_path(conn, :index))
    end
  end
end
