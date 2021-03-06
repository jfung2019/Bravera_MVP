defmodule OmegaBraveraWeb.Router do
  use OmegaBraveraWeb, :router

  alias OmegaBravera.Guardian

  pipeline :browser do
    plug Plug.Logger
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.MaybeAuthPipeline
    plug OmegaBraveraWeb.GoogleAnalytics
    plug :put_root_layout, {OmegaBraveraWeb.LayoutView, :root}
  end

  pipeline :user_authenticated do
    plug Guardian.AuthPipeline
  end

  pipeline :admin_authenticated do
    plug Guardian.AuthPipeline
    plug OmegaBraveraWeb.AdminLoggedIn
  end

  pipeline :super_admin_authenticated do
    plug Guardian.AuthPipeline
    plug OmegaBraveraWeb.SuperAdminAuth
  end

  pipeline :api do
    plug Plug.Logger
    plug :accepts, ["json"]
  end

  pipeline :absinthe_api do
    plug OmegaBraveraWeb.Api.Context
  end

  scope "/" do
    pipe_through :api

    # Strava API Endpoints for Webhooks
    scope "/strava", OmegaBraveraWeb do
      get "/webhook-callback", StravaController, :get_webhook_callback
      post "/webhook-callback", StravaController, :post_webhook_callback
    end

    get "/api/v1/picture-upload-presign", OmegaBraveraWeb.ApiController, :presign

    scope "/" do
      pipe_through :absinthe_api

      forward "/api", Absinthe.Plug, schema: OmegaBraveraWeb.Api.Schema

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: OmegaBraveraWeb.Api.Schema,
        socket: OmegaBraveraWeb.UserSocket,
        context: %{pubsub: OmegaBraveraWeb.Endpoint}
    end
  end

  scope "/" do
    get "/health-check", OmegaBraveraWeb.PageController, :health_check

    get "/open-app", OmegaBraveraWeb.PageController, :open_app

    # App related JSON files for Apple Universal Links and Google App Links.
    # Note: Apple instructs that we should NOT append .json to its file.
    get "/.well-known/apple-app-site-association",
        OmegaBraveraWeb.PageController,
        :apple_domain_verification

    get "/.well-known/assetlinks.json",
        OmegaBraveraWeb.PageController,
        :google_domain_verification
  end

  # Bravera user auth
  scope "/user", OmegaBraveraWeb do
    pipe_through :browser

    resources "/sessions", UserSessionController, only: [:create]
    get "/profile/email_settings", EmailSettingsController, :edit
    post "/profile/email_settings", EmailSettingsController, :update

    get "/profile", UserProfileController, :show
    put "/profile/upload_profile_picture", UserProfileController, :update_profile_picture

    scope "/password_reset" do
      resources "/", PasswordController, only: [:new, :create]

      get "/:reset_token/edit", PasswordController, :edit
      put "/:reset_token", PasswordController, :update
    end

    scope "/" do
      pipe_through :user_authenticated
      get "/account/trackers", UserController, :show_trackers
      get "/account/edit", UserController, :edit
      put "/account", UserController, :update
      post "/account", UserController, :update
    end

    get "/account/activate/:email_activation_token", UserController, :activate_email
  end

  # Strava OAuth Routes
  scope "/strava", OmegaBraveraWeb do
    pipe_through :browser

    get "/login/", StravaController, :authenticate
    get "/login/:team_invitation", StravaController, :authenticate
    get "/callback", StravaController, :strava_callback
    get "/connect_strava_account/", StravaController, :connect_strava_account
    get "/connect_callback", StravaController, :connect_strava_callback
    get "/connect_callback_mobile_app", StravaController, :connect_strava_callback_mobile_app
    get "/logout", StravaController, :logout
  end

  pipeline :admin_section do
    plug :browser
    plug :put_layout, {OmegaBraveraWeb.LayoutView, :admin_panel}
  end

  # TODO: fix root layout issue
  pipeline :admin_liveview do
    plug :put_root_layout, {OmegaBraveraWeb.LayoutView, :admin_panel}
  end

  scope "/admin", OmegaBraveraWeb do
    pipe_through [:admin_section]

    resources "/sessions", AdminUserSessionController,
      only: [:new, :create, :delete],
      singleton: true

    resources "/reset-password", AdminUserPasswordController,
      except: [:index, :delete],
      param: "reset_token"

    scope "/" do
      pipe_through [:super_admin_authenticated]
      get "/dashboard", AdminUserPageController, :index
      resources "/locations", AdminPanelLocationsController
      resources "/admin-users", AdminUserController
      resources "/users", AdminPanelUserController, only: [:index, :show, :edit, :delete]
      put "/users/:id/edit", AdminPanelUserController, :update
      resources "/activities", AdminPanelActivityController, only: [:new, :create]

      resources "/offer-activities", AdminPanelOfferChallengeActivityController,
        only: [:new, :create]

      resources "/offer-rewards", AdminPanelOfferRewardController, except: [:delete]
      resources "/offer-vendors", AdminPanelOfferVendorController, except: [:delete]

      post "/activities/create_imported_strava_activity",
           AdminPanelActivityController,
           :create_imported_strava_activity

      resources "/sync_activities", AdminPanelActivitiesSyncerController, only: [:index]

      resources "/emails", AdminPanelEmailsController, except: [:delete]
      get "/challenges", AdminPanelChallengesController, :index

      resources "/ngos", AdminPanelNGOController, only: [:index, :new, :create] do
        resources "/challenges", AdminPanelChallengesController,
          only: [:show, :edit, :update],
          param: "slug"
      end

      get "/ngos/:slug", AdminPanelNGOController, :show
      get "/ngos/:slug/edit", AdminPanelNGOController, :edit
      put "/ngos/:slug", AdminPanelNGOController, :update
      get "/ngo/:slug/statement", AdminPanelNGOController, :statement
      get "/ngo/:slug/statement/monthly/", AdminPanelNGOController, :export_statement
      get "/ngo/:slug/opt-in/", AdminPanelNGOController, :export_ngo_opt_in_mailing_list
      resources "/points", AdminPanelPointsController, only: [:new, :create]
      resources "/offers", AdminPanelOfferController, param: "slug"
      resources "/offer-partners", AdminPanelOfferPartnerController, only: [:create, :delete]
      get "/offers/:slug/statement", AdminPanelOfferController, :statement
      get "/offers/:slug/statement/monthly/", AdminPanelOfferController, :export_statement
      get "/view-as-org/:id", AdminPanelOrganizationController, :view_as
      put "/block_org/:id", AdminPanelOrganizationController, :block
      resources "/organizations", AdminPanelOrganizationController
      resources "/organization_members", AdminPanelOrganizationMemberController

      scope "/" do
        pipe_through [:admin_liveview]
        live "/offers/:slug/images", AdminOfferImages
      end

      resources "/group_approvals", AdminPanelGroupApprovalController, only: [:show, :create]

      resources "/offer_approvals", AdminPanelOfferApprovalController,
        only: [:show, :create],
        param: "slug"
    end

    scope "/" do
      pipe_through [:admin_authenticated, :super_admin_authenticated]

      scope "/" do
        pipe_through [:admin_liveview]
        live "/groups/:id/images", AdminPartnerImages
        live "/groups/:id/leaderboards", OrgGroupLeaderboardsLive, as: "admin_leaderboard"
      end

      resources "/groups", AdminPanelPartnerController, except: [:delete] do
        resources "/locations", AdminPanelPartnerLocationController, except: [:index]
        resources "/members", AdminPanelPartnerMemberController, only: [:index, :delete]
      end
    end
  end

  pipeline :org_section do
    plug :browser
    plug :put_layout, {OmegaBraveraWeb.LayoutView, :org_panel}
  end

  pipeline :org_liveview do
    plug :put_root_layout, {OmegaBraveraWeb.LayoutView, :org_panel}
  end

  pipeline :org_authenticated do
    plug Guardian.AuthPipeline
    plug OmegaBraveraWeb.OrgAuth
    plug OmegaBraveraWeb.MerchantConstraint
    plug OmegaBraveraWeb.CheckBlockedOrg
  end

  pipeline :merchant_section do
    plug OmegaBraveraWeb.MerchantSection
  end

  scope "/organization", OmegaBraveraWeb do
    pipe_through [:org_section]

    resources "/sessions", PartnerUserSessionController,
      only: [:new, :create, :delete],
      singleton: true

    resources "/password", PartnerUserPasswordController, except: [:delete], param: "reset_token"
    resources "/register", PartnerUserRegisterController, only: [:new, :create]
    get "/activate/:email_activation_token", PartnerUserSessionController, :activate_email
    get "/blocked", OrgPanelDashboardController, :blocked

    scope "/merchant" do
      pipe_through [:merchant_section]

      resources "/register", PartnerUserRegisterController,
        only: [:new, :create],
        as: :merchant_register
    end

    scope "/" do
      pipe_through [:org_authenticated]
      get "/dashboard", OrgPanelDashboardController, :index

      resources "/groups", OrgPanelPartnerController, except: [:delete] do
        live "/:id/leaderboards", OrgGroupLeaderboardsLive
        resources "/locations", OrgPanelPartnerLocationController, except: [:index]
        resources "/members", OrgPanelPartnerMemberController, only: [:index, :delete]
      end

      resources "/points", OrgPanelPointsController, only: [:new, :create]

      scope "/online-offers" do
        resources "/", OrgPanelOnlineOffersController, param: "slug"
        get "/:slug/statement", OrgPanelOnlineOffersController, :statement
        get "/:slug/statement/monthly/", OrgPanelOnlineOffersController, :export_statement
        post "/:slug/review", OrgPanelOnlineOffersController, :review
      end

      scope "/offline-offers" do
        resources "/", OrgPanelOfflineOffersController, param: "slug"
        get "/:slug/statement", OrgPanelOfflineOffersController, :statement
        get "/:slug/statement/monthly/", OrgPanelOfflineOffersController, :export_statement
      end

      scope "/" do
        pipe_through [:org_liveview]

        live "/groups/:id/leaderboards", OrgGroupLeaderboardsLive
        live "/offers/:slug/images", OrgOfferImages
        live "/groups/:id/images", OrgPartnerImages
      end

      resources "/offer-partners", OrgPanelOfferPartnerController, only: [:create, :delete]
      get "/offer-partners/:id", OrgPanelOfferPartnerController, :approval
      resources "/claim-ids", OrgPanelOfferVendorController, except: [:delete]
      resources "/rewards", OrgPanelOfferRewardController, except: [:delete]
      get "/guides", OrgPanelDashboardController, :guides
      get "/admin-logged-in", OrgPanelDashboardController, :view_as
    end
  end

  # Offers
  scope "/offers", OmegaBraveraWeb do
    pipe_through [:browser]

    resources "/", Offer.OfferController, only: [], param: "slug" do
      resources "/", Offer.OfferChallengeController, only: [], param: "slug" do
        get "/activities", PageController, :not_found
        get "/:redeem_token", PageController, :not_found
        get "/redeem/:redeem_token", Offer.OfferChallengeController, :new_redeem
        post "/:redeem_token", Offer.OfferChallengeController, :save_redeem
        put "/:redeem_token", Offer.OfferChallengeController, :save_redeem
        post "/invite/team_members", Offer.OfferChallengeController, :invite_team_members
        get "/add_team_member/:invitation_token", Offer.OfferChallengeController, :add_team_member

        get "/resend_invitation/:invitation_token",
            Offer.OfferChallengeController,
            :resend_invitation

        get "/cancel_invitation/:invitation_token",
            Offer.OfferChallengeController,
            :cancel_invitation

        post "/kick_team_member/:user_id", Offer.OfferChallengeController, :kick_team_member
      end
    end
  end

  scope "/", OmegaBraveraWeb do
    pipe_through :browser

    get "/signup", PageController, :signup
    # TODO: possibly remove later if really not required.
    # get "/login", PageController, :login
    get "/login/:team_invitation", PageController, :login
    get "/404", PageController, :not_found
    get "/500", PageController, :not_found
    resources "/email-signup", UserController, only: [:new, :create]
    resources "/teams", TeamController, only: [:new, :create, :show]
    resources "/tips", TipController, only: [:new, :create, :show]
    get "/", PageController, :index
    #    get "/ngos", NGOController, :index
    #
    #    resources "/", NGOController, only: [:show], param: "slug" do
    #      get "/leaderboard", NGOController, :leaderboard, param: "slug"
    #
    #      resources "/", NGOChalController, only: [:show, :new, :create], param: "slug" do
    #        resources "/donations", DonationController, only: [:create]
    #        post "/follow_on_donation", DonationController, :create_and_charge_follow_on_donation
    #        get "/donors", DonationController, :index
    #        get "/activities", ActivityController, :index
    #        post "/invite_buddies", NGOChalController, :invite_buddies
    #        post "/invite_team_members", NGOChalController, :invite_team_members
    #        get "/add_team_member/:invitation_token", NGOChalController, :add_team_member
    #        get "/resend_invitation/:invitation_token", NGOChalController, :resend_invitation
    #        get "/cancel_invitation/:invitation_token", NGOChalController, :cancel_invitation
    #        post "/kick_team_member/:user_id", NGOChalController, :kick_team_member
    #      end
    #    end

    get "/*path", PageController, :not_found
  end
end
