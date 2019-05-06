defmodule OmegaBraveraWeb.AdminUserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBraveraWeb.AdminLoggedIn

  alias OmegaBravera.Accounts.{User, AdminUser}

  def new(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %User{} ->
        redirect(conn, to: page_path(conn, :index))

      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      _ ->
        render(conn, "new.html")
    end
  end

  def create(conn, %{"session" => %{"email" => email, "password" => pass}}) do
    case AdminLoggedIn.login_by_email_and_pass(conn, email, pass) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: admin_user_page_path(conn, :index))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> render("new.html")
    end
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end
end
