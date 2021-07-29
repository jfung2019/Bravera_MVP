defmodule OmegaBraveraWeb.AdminUserPasswordController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.AdminUser

  def new(conn, _param), do: render(conn, "new.html")

  def create(conn, %{"reset_token" => %{"email" => email}}) do
    with %AdminUser{} = admin_user <- Accounts.find_admin_user_by_email(email),
         {:ok, _updated_admin} <- Accounts.send_reset_password_token(admin_user) do
      conn
      |> put_flash(:info, gettext("Password reset link sent. Please check your inbox."))
      |> render("new.html")
    else
      nil ->
        conn
        |> put_flash(:error, gettext("There's no account associated with that email"))
        |> render("new.html")

      _ ->
        conn
        |> put_flash(:error, gettext("Cannot reset password"))
        |> render("new.html")
    end
  end

  def edit(conn, %{"reset_token" => reset_token}) do
    case Accounts.find_admin_user_by_reset_token(reset_token) do
      {:ok, admin_user} ->
        render(conn, "edit.html",
          admin_user: admin_user,
          reset_token: reset_token,
          changeset: Accounts.admin_user_reset_password_changeset(admin_user)
        )

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, gettext("Password reset token expired"))
        |> redirect(to: Routes.admin_user_password_path(conn, :new))

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: Routes.admin_user_password_path(conn, :new))
    end
  end

  def update(conn, %{"reset_token" => reset_token, "admin_user" => params}) do
    with {:ok, admin} <- Accounts.find_admin_user_by_reset_token(reset_token),
         {:ok, _admin_user} <- Accounts.reset_admin_user_password(admin, params) do
      conn
      |> put_flash(:info, "Password reset successfully!")
      |> redirect(to: Routes.admin_user_session_path(conn, :new))
    else
      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: Routes.admin_user_password_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "Password reset token expired")
        |> redirect(to: Routes.admin_user_password_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, admin} = Accounts.find_admin_user_by_reset_token(reset_token)

        render(conn, "edit.html",
          admin_user: admin,
          reset_token: reset_token,
          changeset: changeset
        )
    end
  end
end
