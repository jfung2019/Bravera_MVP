defmodule OmegaBraveraWeb.AdminUserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.AdminUser

  def index(conn, _params) do
    admin_users = Accounts.list_admin_users()
    render(conn, "index.html", admin_users: admin_users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_admin_user(%AdminUser{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"admin_user" => admin_user_params}) do
    case Accounts.create_admin_user(admin_user_params) do
      {:ok, admin_user} ->
        conn
        |> put_flash(:info, "Admin user created successfully.")
        |> redirect(to: Routes.admin_user_path(conn, :show, admin_user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    admin_user = Accounts.get_admin_user!(id)
    render(conn, "show.html", admin_user: admin_user)
  end

  def edit(conn, %{"id" => id}) do
    admin_user = Accounts.get_admin_user!(id)
    changeset = Accounts.change_admin_user(admin_user)
    render(conn, "edit.html", admin_user: admin_user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "admin_user" => admin_user_params}) do
    admin_user = Accounts.get_admin_user!(id)

    case Accounts.update_admin_user(admin_user, admin_user_params) do
      {:ok, admin_user} ->
        conn
        |> put_flash(:info, "Admin user updated successfully.")
        |> redirect(to: Routes.admin_user_path(conn, :show, admin_user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", admin_user: admin_user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    admin_user = Accounts.get_admin_user!(id)
    {:ok, _admin_user} = Accounts.delete_admin_user(admin_user)

    conn
    |> put_flash(:info, "Admin user deleted successfully.")
    |> redirect(to: Routes.admin_user_path(conn, :index))
  end
end
