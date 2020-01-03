defmodule OmegaBraveraWeb.Router do
  use OmegaBraveraWeb, :router

  alias OmegaBravera.Guardian

  pipeline :browser do
    plug(Plug.Logger)
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

  pipeline :api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
  end

  pipeline :absinthe_api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug OmegaBraveraWeb.Api.Context
  end

  scope "/" do
    pipe_through :absinthe_api

    forward "/api", Absinthe.Plug, schema: OmegaBraveraWeb.Api.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: OmegaBraveraWeb.Api.Schema,
      socket: OmegaBraveraWeb.UserSocket,
      context: %{pubsub: OmegaBraveraWeb.Endpoint}
  end

  scope "/" do
    get("/health-check", OmegaBraveraWeb.PageController, :health_check)

    get("/open-app", OmegaBraveraWeb.PageController, :open_app)

    # App related JSON files for Apple Universal Links and Google App Links.
    # Note: Apple instructs that we should NOT append .json to its file.
    get(
      "/.well-known/apple-app-site-association",
      OmegaBraveraWeb.PageController,
      :apple_domain_verification
    )

    get(
      "/.well-known/assetlinks.json",
      OmegaBraveraWeb.PageController,
      :google_domain_verification
    )
  end

  # Bravera user auth
  scope "/user", OmegaBraveraWeb do
    pipe_through(:browser)

    resources("/sessions", UserSessionController, only: [:create])
    get("/profile/email_settings", EmailSettingsController, :edit)
    post("/profile/email_settings", EmailSettingsController, :update)

    get("/profile", UserProfileController, :show)
    put("/profile/upload_profile_picture", UserProfileController, :update_profile_picture)

    scope "/password_reset" do
      resources("/", PasswordController, only: [:new, :create])

      get("/:reset_token/edit", PasswordController, :edit)
      put("/:reset_token", PasswordController, :update)
    end

    scope "/" do
      pipe_through :user_authenticated
      get("/account/trackers", UserController, :show_trackers)
      get("/account/edit", UserController, :edit)
      put("/account", UserController, :update)
      post("/account", UserController, :update)
    end

    get("/account/activate/:email_activation_token", UserController, :activate_email)
  end

  # Strava OAuth Routes
  scope "/strava", OmegaBraveraWeb do
    pipe_through(:browser)

    get("/login/", StravaController, :authenticate)
    get("/login/:team_invitation", StravaController, :authenticate)
    get("/callback", StravaController, :strava_callback)
    get("/connect_strava_account/", StravaController, :connect_strava_account)
    get("/connect_callback", StravaController, :connect_strava_callback)
    get("/connect_callback_mobile_app", StravaController, :connect_strava_callback_mobile_app)
    get("/logout", StravaController, :logout)
  end

  # Strava API Endpoints for Webhooks
  scope "/strava", OmegaBraveraWeb do
    pipe_through(:api)

    get("/webhook-callback", StravaController, :get_webhook_callback)
    post("/webhook-callback", StravaController, :post_webhook_callback)
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
      resources "/locations", AdminPanelLocationsController
      resources("/admin-users", AdminUserController)
      resources("/users", AdminPanelUserController, only: [:index, :show, :edit])
      put("/users/:id/edit", AdminPanelUserController, :update)
      resources("/activities", AdminPanelActivityController, only: [:new, :create])

      resources("/offer-activities", AdminPanelOfferChallengeActivityController,
        only: [:new, :create]
      )

      resources("/offer-rewards", AdminPanelOfferRewardController,
        only: [:index, :new, :create, :edit, :update]
      )

      resources("/offer-vendors", AdminPanelOfferVendorController,
        only: [:index, :new, :create, :edit, :update]
      )

      # get(
      #   "/activities/import_activity_from_strava",
      #   AdminPanelActivityController,
      #   :new_import_activity_from_strava
      # )

      post(
        "/activities/create_imported_strava_activity",
        AdminPanelActivityController,
        :create_imported_strava_activity
      )

      resources("/sync_activities", AdminPanelActivitiesSyncerController, only: [:index])

      resources("/emails", AdminPanelEmailsController,
        only: [:index, :new, :create, :edit, :update]
      )

      get("/challenges", AdminPanelChallengesController, :index)

      resources("/ngos", AdminPanelNGOController, only: [:index, :new, :create]) do
        resources("/challenges", AdminPanelChallengesController,
          only: [:show, :edit, :update],
          param: "slug"
        )
      end

      get("/ngos/:slug", AdminPanelNGOController, :show)
      get("/ngos/:slug/edit", AdminPanelNGOController, :edit)
      put("/ngos/:slug", AdminPanelNGOController, :update)
      get("/ngo/:slug/statement", AdminPanelNGOController, :statement)
      get("/ngo/:slug/statement/monthly/", AdminPanelNGOController, :export_statement)
      get("/ngo/:slug/opt-in/", AdminPanelNGOController, :export_ngo_opt_in_mailing_list)

      resources("/offers", AdminPanelOfferController, only: [:index, :new, :create])
      resources("/points", AdminPanelPointsController, only: [:new, :create])

      get("/offers/:slug", AdminPanelOfferController, :show)
      get("/offers/:slug/edit", AdminPanelOfferController, :edit)
      put("/offers/:slug", AdminPanelOfferController, :update)
      get("/offers/:slug/statement", AdminPanelOfferController, :statement)
      get("/offers/:slug/statement/monthly/", AdminPanelOfferController, :export_statement)
    end

    scope "/api" do
      pipe_through([:admin_authenticated, :api])

      get("/challenge_dates", AdminPanelActivityController, :get_challenge_dates)
    end
  end

  # Offers
  scope "/offers", OmegaBraveraWeb do
    pipe_through(:browser)

    resources "/", Offer.OfferController, only: [:index], param: "slug" do
      resources "/", Offer.OfferChallengeController, only: [:show, :new, :create], param: "slug" do
        get("/activities", Offer.OfferChallengeActivityController, :index)
        get("/:redeem_token", Offer.OfferChallengeController, :send_qr_code)
        get("/redeem/:redeem_token", Offer.OfferChallengeController, :new_redeem)
        post("/:redeem_token", Offer.OfferChallengeController, :save_redeem)
        put("/:redeem_token", Offer.OfferChallengeController, :save_redeem)
        post("/invite/team_members", Offer.OfferChallengeController, :invite_team_members)

        get(
          "/add_team_member/:invitation_token",
          Offer.OfferChallengeController,
          :add_team_member
        )

        get(
          "/resend_invitation/:invitation_token",
          Offer.OfferChallengeController,
          :resend_invitation
        )

        get(
          "/cancel_invitation/:invitation_token",
          Offer.OfferChallengeController,
          :cancel_invitation
        )

        post(
          "/kick_team_member/:user_id",
          Offer.OfferChallengeController,
          :kick_team_member
        )
      end
    end
  end

  scope "/", OmegaBraveraWeb do
    pipe_through(:browser)

    get("/signup", PageController, :signup)

    get("/login", PageController, :login)
    get("/login/:team_invitation", PageController, :login)

    get("/404", PageController, :not_found)
    get("/500", PageController, :not_found)

    resources("/email-signup", UserController, only: [:new, :create])

    resources("/teams", TeamController, only: [:new, :create, :show])

    resources("/tips", TipController, only: [:new, :create, :show])

    get("/", PageController, :index)

    get("/ngos", NGOController, :index)

    resources "/", NGOController, only: [:show], param: "slug" do
      get("/leaderboard", NGOController, :leaderboard, param: "slug")

      resources "/", NGOChalController, only: [:show, :new, :create], param: "slug" do
        resources("/donations", DonationController, only: [:create])
        post("/follow_on_donation", DonationController, :create_and_charge_follow_on_donation)
        get("/donors", DonationController, :index)
        get("/activities", ActivityController, :index)
        post("/invite_buddies", NGOChalController, :invite_buddies)
        post("/invite_team_members", NGOChalController, :invite_team_members)
        get("/add_team_member/:invitation_token", NGOChalController, :add_team_member)
        get("/resend_invitation/:invitation_token", NGOChalController, :resend_invitation)
        get("/cancel_invitation/:invitation_token", NGOChalController, :cancel_invitation)
        post("/kick_team_member/:user_id", NGOChalController, :kick_team_member)
      end
    end

    get("/*path", PageController, :not_found)
  end
end
