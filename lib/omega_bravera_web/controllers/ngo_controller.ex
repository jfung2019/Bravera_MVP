defmodule OmegaBraveraWeb.NGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Fundraisers, Challenges}
  # alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.NGOChal

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos()
    changeset = Challenges.change_ngo_chal(%NGOChal{})

    render(conn, "index.html", ngos: ngos, changeset: changeset)
  end

  def show(conn, %{"id" => id}) do
    ngo = Fundraisers.get_ngo!(id)
    render(conn, "show.html", ngo: ngo)
  end

end
