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

  # Strava OAuth Routes
  scope "/strava", OmegaBraveraWeb do
    pipe_through :browser

    get "/login", StravaController, :authenticate
    get "/callback", StravaController, :strava_callback
    get "/logout", StravaController, :logout

  end

  scope "/", OmegaBraveraWeb do
    pipe_through :browser # Use the default browser stack

    resources "/users", UserController
    #donations nested here?
    # (donations given + paid)
    resources "/ngos", NGOController
    #donations (ngo total raised) nested here?
    resources "/ngo_chals", NGOChalController
    # donations (chal_total) nested here?
    resources "/donations", DonationController

    # for callbacks
    resources "/strava", StravaController

    # maybe add: challenge data

    get "/", PageController, :index

    resources "/", NGOController, only: [:show] do
      resources "/", NGOChalController, only: [:show, :new, :create] do
        resources "/donate", DonationController, only: [:show, :new, :create]
      end
    end

  end

  scope "/pass-reset", OmegaBraveraWeb do
    pipe_through :browser

    resources "/", PasswordController, only: [:new, :create]

    get "/:token/edit", PasswordController, :edit
    put "/:token", PasswordController, :update
  end


  # Other scopes may use custom stacks.
  # scope "/api", OmegaBraveraWeb do
  #   pipe_through :api
  # end
end
