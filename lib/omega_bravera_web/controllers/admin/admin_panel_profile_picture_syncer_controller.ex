defmodule OmegaBraveraWeb.AdminPanelProfilePictureController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.ProfilePictureSyncer

  def index(conn, _params) do
    Task.async(ProfilePictureSyncer, :sync, [])
    render(conn, "index.html")
  end
end
