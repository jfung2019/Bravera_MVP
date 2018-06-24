defmodule OmegaBraveraWeb.NGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Fundraisers.NGO

  def show(conn, %{"id" => id}) do
    ngo = Fundraisers.get_ngo!(id)
    render(conn, "show.html", ngo: ngo)
  end

end
