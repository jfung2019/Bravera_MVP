defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Challenges
  alias OmegaBravera.Challenges.NGOChal

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos()

    user = Guardian.Plug.current_resource(conn)

    changeset = Challenges.change_ngo_chal(%NGOChal{})

    render(conn, "index.html", ngos: ngos, user: user, changeset: changeset)
  end
end
