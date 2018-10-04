defmodule OmegaBraveraWeb.AdminPanelNGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos_preload()
    render(conn, "index.html", ngos: ngos)
  end

  def show(conn, %{"slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug, :preload)
    render(conn, "show.html", ngo: ngo)
  end
end
