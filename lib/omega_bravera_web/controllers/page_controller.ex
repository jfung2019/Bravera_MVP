defmodule OmegaBraveraWeb.PageController do
  use OmegaBraveraWeb, :controller

  # alias OmegaBravera.{Challenges, Fundraisers}
  # alias OmegaBravera.Challenges.NGOChal

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        redirect conn, to: "/signup"
      true ->
        render(conn, "index.html")
    end
  end

  def signup(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        redirect conn, to: "/ngos"
      true ->
        render(conn, "signup.html")
    end
  end
end
