defmodule OmegaBraveraWeb.AdminUserPageController do
  use OmegaBraveraWeb, :controller

  def new(conn, _), do: render(conn, "index.html")
end