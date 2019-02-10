defmodule OmegaBraveraWeb.Router do
  use OmegaBraveraWeb, :router

  alias OmegaBravera.Guardian

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Guardian.MaybeAuthPipeline)
    plug(OmegaBraveraWeb.GoogleAnalytics)
  end

  pipeline :user_authenticated do
    plug(Guardian.AuthPipeline)
  end

  pipeline :admin_authenticated do
    plug(Guardian.AuthPipeline)
    plug(OmegaBraveraWeb.AdminLoggedIn)
  end

  pipeline :dashboard do
    plug(:put_layout, {OmegaBraveraWeb.LayoutView, "dashboard.html"})
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Bravera user auth
  scope "/user", OmegaBraveraWeb do
    pipe_through(:browser)

    resources("/sessions", UserSessionController, only: [:create])
    resources("/profile/settings", SettingController, only: [:new, :create])
    get("/profile/settings", SettingController, :show)
    put("/profile/settings", SettingController, :update)
    get("/profile", UserProfileController, :show)
    get("/profile/settings/edit", SettingController, :edit)
    resources("/password", ChangePasswordController, only: [:new, :create])
    get("/password/edit", ChangePasswordController, :edit)
    post("/password/update", ChangePasswordController, :update)
    put("/password/update", ChangePasswordController, :update)
    get("/account", UserController, :show)
    get("/account/edit", UserController, :edit)
    put("/account", UserController, :update)
    get("/account/activate/:email_activation_token", UserController, :activate_email)
  end

  # Strava OAuth Routes
  scope "/strava", OmegaBraveraWeb do
    pipe_through(:browser)

    get("/login/", StravaController, :authenticate)
    get("/login/:team_invitation", StravaController, :authenticate)
    get("/callback", StravaController, :strava_callback)
    get("/logout", StravaController, :logout)
  end

  # Strava API Endpoints for Webhooks
  scope "/strava", OmegaBraveraWeb do
    pipe_through(:api)

    get("/webhook-callback", StravaController, :get_webhook_callback)
    post("/webhook-callback", StravaController, :post_webhook_callback)
  end

  scope "/dashboard", OmegaBraveraWeb do
    pipe_through([:browser, :user_authenticated, :dashboard])

    get("/", UserController, :dashboard)
    get("/donations", UserController, :user_donations)

    scope "/ngos" do
      get("/", UserController, :ngos)
    end
  end

  pipeline :admin_section do
    plug(:browser)
    plug(:put_layout, {OmegaBraveraWeb.LayoutView, :admin_panel})
  end

  scope "/admin", OmegaBraveraWeb do
    pipe_through([:admin_section])
    resources("/sessions", AdminUserSessionController, only: [:new, :create])
    get("/logout", AdminUserSessionController, :logout)

    scope "/" do
      pipe_through(:admin_authenticated)
      get("/", AdminUserPageController, :index)
      resources("/admin_users", AdminUserController)
      resources("/users", AdminPanelUserController, only: [:index, :show])
      resources("/activities", AdminPanelActivityController, only: [:index, :new, :create])

      get(
        "/activities/import_activity_from_strava",
        AdminPanelActivityController,
        :new_import_activity_from_strava
      )

      post(
        "/activities/create_imported_strava_activity",
        AdminPanelActivityController,
        :create_imported_strava_activity
      )

      resources("/sync_exchange_rate", AdminPanelExchangeRateController, only: [:index])
      resources("/sync_profile_pictures", AdminPanelProfilePictureController, only: [:index])
      get("/challenges", AdminPanelChallengesController, :index)

      resources("/ngos", AdminPanelNGOController, only: [:index, :new, :create]) do
        resources("/challenges", AdminPanelChallengesController, only: [:show, :edit, :update])
      end

      get("/ngos/:slug", AdminPanelNGOController, :show)
      get("/ngos/:slug/edit", AdminPanelNGOController, :edit)
      put("/ngos/:slug", AdminPanelNGOController, :update)
      get("/ngo/:slug/statement", AdminPanelNGOController, :statement)
      get("/ngo/:slug/statement/monthly/", AdminPanelNGOController, :export_statement)
      get("/ngo/:slug/opt-in/", AdminPanelNGOController, :export_ngo_opt_in_mailing_list)
    end

    scope "/api" do
      pipe_through([:admin_authenticated, :api])

      get("/challenge_dates", AdminPanelActivityController, :get_challenge_dates)
    end
  end

  scope "/", OmegaBraveraWeb do
    pipe_through(:browser)

    get("/signup", PageController, :signup)

    get("/login", PageController, :login)
    get("/login/:team_invitation", PageController, :login)

    get("/404", PageController, :notFound)
    get("/500", PageController, :notFound)

    resources("/email-signup", UserController, only: [:new, :create])

    resources("/teams", TeamController, only: [:new, :create, :show])

    resources("/tips", TipController, only: [:new, :create, :show])

    get("/", PageController, :index)

    get("/ngos", NGOController, :index)

    resources "/", NGOController, only: [:show], param: "slug" do
      get("/leaderboard", NGOController, :leaderboard, param: "slug")

      resources "/", NGOChalController, only: [:show, :new, :create], param: "slug" do
        resources("/donations", DonationController, only: [:create])
        get("/donors", DonationController, :index)
        get("/activities", ActivityController, :index)
        post("/invite_buddies", NGOChalController, :invite_buddies)
        post("/invite_team_members", NGOChalController, :invite_team_members)
        get("/add_team_member/:invitation_token", NGOChalController, :add_team_member)
        get("/resend_invitation/:invitation_token", NGOChalController, :resend_invitation)
        get("/cancel_invitation/:invitation_token", NGOChalController, :cancel_invitation)
      end
    end
  end

  scope "/pass-reset", OmegaBraveraWeb do
    pipe_through(:browser)

    resources("/", PasswordController, only: [:new, :create])

    get("/:token/edit", PasswordController, :edit)
    put("/:token", PasswordController, :update)
  end
end
