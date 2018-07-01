defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  # alias OmegaBravera.{Challenges, Fundraisers}
  # alias OmegaBravera.Challenges.NGOChal

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    render(conn, "index.html", user: user)
  end
end
