use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).

config :omega_bravera, OmegaBravera.Endpoint,
  secret_key_base: System.get_env("BASE_SEC")

# Configure your database
config :omega_bravera, OmegaBravera.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATABASE_USERNAME"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST"),
  pool_size: 20


# Strava dev config

config :strava,
  client_id: System.get_env("STRAVA_ID"),
  client_secret: System.get_env("STRAVA_SEC"),
  access_token: System.get_env("STRAVA_TOK"),
  redirect_uri: System.get_env("STRAVA_CALLBACK")

# Stripy dev config

config :stripy,
  secret_key: System.get_env("STRIPY"),
  endpoint: System.get_env("STRIPY_ENDPT")

# Guardian config

config :omega_bravera, OmegaBravera.Guardian,
       issuer: "Bravera.co",
       secret_key: System.get_env("OMEGA_SEC")

 # Email config

 config :omega_bravera, OmegaBravera.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: System.get_env("SENDGRID_SEC")
