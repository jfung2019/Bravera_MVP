use Mix.Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
       http: [port: System.get_env("PORT") || 4000],
       url: [host: System.get_env("APP_HOST"), port: 443, scheme: "https"]

config :omega_bravera, OmegaBraveraWeb.Endpoint,
       secret_key_base: System.get_env("SECRET_KEY_BASE")

config :omega_bravera, OmegaBravera.Repo,
       url: System.get_env("DATABASE_URL"),
       pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
       ssl: !is_nil(System.get_env("DATABASE_SSL"))

config :strava,
       client_id: System.get_env("STRAVA_CLIENT_ID"),
       client_secret: System.get_env("STRAVA_CLIENT_SECRET"),
       access_token: System.get_env("STRAVA_ACCESS_TOKEN"),
       redirect_uri: System.get_env("STRAVA_REDIRECT_URI")

config :stripy,
       secret_key: System.get_env("STRIPE_SECRET_KEY")

config :omega_bravera, :stripe_public_key, System.get_env("STRIPE_PUBLIC_KEY")

# Guardian config
config :omega_bravera, OmegaBravera.Guardian,
       secret_key: System.get_env("GUARDIAN_SECRET_KEY")

# Email config
config :omega_bravera, OmegaBravera.Mailer,
       api_key: System.get_env("SENDGRID_API_KEY")

config :sendgrid,
       api_key: System.get_env("SENDGRID_API_KEY"),
       sandbox_enable: is_nil(System.get_env("ENABLE_EMAILS"))

# S3 Bucket
config :ex_aws,
       access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
       secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
       region: System.get_env("AWS_REGION")

config :omega_bravera, :images_bucket_name, System.get_env("S3_BUCKET_NAME")

# Manual activities
config :omega_bravera,
       :enable_manual_activities,
       not is_nil(System.get_env("ENABLE_MANUAL_ACTIVITIES"))
