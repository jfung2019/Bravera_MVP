defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Accounts.{AdminUser, User}

  def notFound(conn, _params) do
    render(conn, "404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
  end

  def index(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      %User{} ->
        redirect(conn, to: "/ngos")

      _ ->
        render(conn, "index.html")
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

  def login(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: admin_user_page_path(conn, :index))

      %User{} ->
        redirect(conn, to: user_profile_path(conn, :show))

      _ ->
        render(conn, "login.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end
end
