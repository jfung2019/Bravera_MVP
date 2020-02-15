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
  pubsub: [name: OmegaBravera.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "TdyCh4NgcCaGWqBxvPMlKWGCgHp0WunS"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: "/var/log/my_app/error.log",
  level: :error

config :logger, :info,
  path: "/var/log/info.log",
  level: :info

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :postgrex, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
