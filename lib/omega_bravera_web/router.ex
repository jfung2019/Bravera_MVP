defmodule OmegaBraveraWeb.Router do
  use OmegaBraveraWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OmegaBraveraWeb do
    pipe_through :browser # Use the default browser stack

    resources "/users", UserController
    resources "/ngos", NGOController
    resources "/ngo_chals", NGOChalController
    resources "/strava", StravaController


    get "/", HomeController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", OmegaBraveraWeb do
  #   pipe_through :api
  # end
end
