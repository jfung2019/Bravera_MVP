defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts.{AdminUser, User}

  plug OmegaBraveraWeb.AddDriftApp when action in [:index]

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
  end

  def index(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      _ ->
        # TODO: find a better solution to pass csrf into lib/omega_bravera_web/live/live_user_login.ex -Sherief
        # bug: https://github.com/phoenixframework/phoenix_live_view/issues/111
        render(conn, "index.html", csrf: Plug.CSRFProtection.get_csrf_token)
    end
  end

  def signup(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        render(conn, "signup.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      _ ->
        redirect(conn, to: user_profile_path(conn, :show))
    end
  end

  def login(conn, %{"team_invitation" => team_invitation}) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      %User{} ->
        redirect(conn, to: team_invitation)

      _ ->
        render(conn, "login.html",
          team_invitation: team_invitation,
          layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"}
        )
    end
  end

  def login(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      %User{} ->
        redirect(conn, to: user_profile_path(conn, :show))

      _ ->
        render(conn, "login.html",
          team_invitation: nil,
          layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"}
        )
    end
  end

  def health_check(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> text("")
  end
end
