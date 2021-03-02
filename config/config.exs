# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :omega_bravera,
  ecto_repos: [OmegaBravera.Repo],
  cookie_age: 2 * 7 * 24 * 60 * 60,
  # Set ENV
  env: Mix.env(),
  # GA Key
  google_analytics_id: Map.get(System.get_env(), "GOOGLE_ANALYTICS_ID", "UA-123069307-1"),
  # Manual activities
  enable_manual_activities: false,
  upload_manager: OmegaBravera.UploadManager

# Configures the endpoint
config :omega_bravera, OmegaBraveraWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iKoMsrgx4QISCepc7OH9B5FUWQ0xTtHPQr8bChKjP5Z98pwVRIn9/lMax8nflh9v",
  render_errors: [view: OmegaBraveraWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: OmegaBravera.PubSub,
  live_view: [signing_salt: "TdyCh4NgcCaGWqBxvPMlKWGCgHp0WunS"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :postgrex, :json_library, Jason

# Turbo pagination
config :turbo_ecto, Turbo.Ecto, repo: OmegaBravera.Repo, per_page: 20

config :omega_bravera, Oban,
  repo: OmegaBravera.Repo,
  prune: {:maxlen, 10_000},
  queues: [default: 10, email: 10, notification: 10],
  crontab: [
    {"0 0 * * *", OmegaBravera.Notifications.Jobs.NotifyDaysNoActivity},
    {"0 4 * * *", OmegaBravera.Notifications.Jobs.NotifyExpiringReward},
    {"0 8 */3 * *", OmegaBravera.Notifications.Jobs.NotifyNewGroupMembers},
    {"0 0 * * *", OmegaBravera.Groups.Jobs.NewPartnerJoined}
  ]

config :omega_bravera, OmegaBravera.Guardian,
  allowed_drift: 3.154e+10,
  ttl: {52, :weeks},
  max_age: {78, :weeks}

config :pigeon, :fcm,
  fcm_default: %{
    key:
      "AAAARgqNKow:APA91bGW6f0F7RGp-TqPDbpKIUutW6JkSX6R9R-yemb8vjRvODB6ZwM-0O2FwiuGaXcMomkY1PgwesMaRISrYU5gI01Fto8H67_p2hXSyglB0LJShvRnQEto-PCrYsq0Uz8M2ps8P9eK"
  }

config :omega_bravera, OmegaBraveraWeb.Gettext, locales: ~w(en zh)
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
