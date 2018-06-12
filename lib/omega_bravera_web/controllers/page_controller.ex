defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
