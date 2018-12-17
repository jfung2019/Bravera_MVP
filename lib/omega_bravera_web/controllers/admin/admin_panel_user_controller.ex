defmodule OmegaBraveraWeb.AdminPanelUserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Repo}

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = id |> Accounts.get_user!() |> Repo.preload(:strava)
    render(conn, "show.html", user: user)
  end
end
