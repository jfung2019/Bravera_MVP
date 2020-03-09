defmodule OmegaBraveraWeb.UserSessionController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def create(conn, %{
        "session" => %{"email" => email, "password" => pass},
        "add_team_member_redirect_uri" => add_team_member_redirect_uri
      }) do
    case Accounts.email_password_auth(email, pass) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: add_team_member_redirect_uri)

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> redirect(to: Routes.page_path(conn, :login))
    end
  end

  def create(conn, %{
        "session" => %{"email" => email, "password" => pass},
        "redirect_uri" => redirect_uri
      }) do
    case Accounts.email_password_auth(email, pass) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: redirect_uri)

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> redirect(to: Routes.page_path(conn, :login))
    end
  end

  def create(conn, %{"session" => %{"email" => email, "password" => pass}}) do
    case Accounts.email_password_auth(email, pass) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: redirect_path(conn))

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> redirect(to: Routes.page_path(conn, :login))
    end
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end

  defp redirect_path(conn) do
    case get_session(conn, "after_login_redirect") do
      nil -> Routes.user_profile_path(conn, :show)
      path -> path
    end
  end
end
