# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
  config :omega_bravera,
    ecto_repos: [OmegaBravera.Repo]


# Configures the endpoint
config :omega_bravera, OmegaBraveraWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iKoMsrgx4QISCepc7OH9B5FUWQ0xTtHPQr8bChKjP5Z98pwVRIn9/lMax8nflh9v",
  render_errors: [view: OmegaBraveraWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: OmegaBravera.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
