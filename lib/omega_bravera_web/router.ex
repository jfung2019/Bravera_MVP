defmodule OmegaBraveraWeb.Router do
  use OmegaBraveraWeb, :router

  alias OmegaBravera.Guardian

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.MaybeAuthPipeline
  end

  pipeline :jwt_authenticated do
    plug Guardian.AuthPipeline
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

  # Strava API Endpoints
  scope "/strava", BraveraWeb do
    pipe_through :api

    get "/webhook-callback", StravaController, :get_webhook_callback
    post "/webhook-callback", StravaController, :post_webhook_callback
  end

  scope "/", BraveraWeb do
    pipe_through [:browser, :jwt_authenticated]

    scope "/dashboard" do
      get "/", UserController, :dashboard

      get "/settings", UserController, :settings
      get "/challenges", UserController, :challenges
      get "/donations", UserController, :donations
      get "/causes", UserController, :causes
    end

  end

  scope "/", OmegaBraveraWeb do
    pipe_through :browser # Use the default browser stack

    resources "/users", UserController
    #donations nested here?
    # (donations given + paid)

    resources "/teams", TeamController

    resources "/tips", TipController

    # for callbacks
    resources "/strava", StravaController
    # maybe add: challenge data

    resources "/settings", SettingController, only: [:show, :edit, :update]

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

end
