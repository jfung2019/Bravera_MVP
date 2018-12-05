defmodule OmegaBraveraWeb.AdminPanelExchangeRateController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.ExchangeRateSyncer

  def index(conn, _params) do
    Task.async(ExchangeRateSyncer, :sync, [])
    render(conn, "index.html")
  end
end
