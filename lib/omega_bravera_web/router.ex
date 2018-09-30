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
    plug OmegaBraveraWeb.GoogleAnalytics
  end

  pipeline :user_authenticated do
    plug Guardian.AuthPipeline
  end

  pipeline :admin_authenticated do
    plug Guardian.AuthPipeline
    plug OmegaBraveraWeb.AdminLoggedIn
  end

  pipeline :dashboard do
    plug :put_layout, {OmegaBraveraWeb.LayoutView, "dashboard.html"}
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

  # Strava API Endpoints for Webhooks
  scope "/strava", OmegaBraveraWeb do
    pipe_through :api

    get "/webhook-callback", StravaController, :get_webhook_callback
    post "/webhook-callback", StravaController, :post_webhook_callback
  end

  scope "/dashboard", OmegaBraveraWeb do
    pipe_through [:browser, :user_authenticated, :dashboard]

    get "/", UserController, :dashboard
    get "/donations", UserController, :user_donations

    scope "/ngos" do
      get "/", UserController, :ngos
    end

    resources "/account", UserController, only: [:show, :edit, :update]

    resources "/settings", SettingController, only: [:show, :edit, :update]
  end


  scope "/admin", OmegaBraveraWeb do
    pipe_through [:browser, :admin_authenticated]

    resources "/admin_users", AdminUserController
  end

  scope "/", OmegaBraveraWeb do
    pipe_through :browser

    get "/signup", PageController, :signup

    get "/login", PageController, :login

    get "/404", PageController, :notFound
    get "/500", PageController, :notFound

    resources "/email-signup", UserController, only: [:new, :create]

    resources "/teams", TeamController, only: [:new, :create, :show]

    resources "/tips", TipController, only: [:new, :create, :show]

    get "/", PageController, :index

    get "/ngos", NGOController, :index

    resources "/", NGOController, only: [:show], param: "slug" do
      get "/leaderboard", NGOController, :leaderboard, param: "slug"
      resources "/", NGOChalController, only: [:show, :new, :create], param: "slug" do
        resources "/donations", DonationController, only: [:create]
        get "/donors", DonationController, :index
        get "/activities", ActivityController, :index
        post "/invite_buddies", NGOChalController, :invite_buddies
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
