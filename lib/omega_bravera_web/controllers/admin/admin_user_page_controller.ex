defmodule OmegaBraveraWeb.AdminUserPageController do
  use OmegaBraveraWeb, :controller

  def index(conn, _), do: render(conn, "index.html")
end
