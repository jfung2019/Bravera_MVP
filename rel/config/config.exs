use Mix.Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
       http: [port: System.get_env("PORT") || 4000],
       url: [host: System.fetch_env!("HOST_URL"), port: 443, scheme: "https"],
       live_view: [signing_salt: System.fetch_env!("LIVEVIEW_SIGNING_SALT")]

config :sendgrid,
       api_key: System.fetch_env!("SENDGRID_API_KEY")

config :omega_bravera, OmegaBravera.Endpoint,
       secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

# Strava dev config
config :strava,
       client_id: System.fetch_env!("STRAVA_CLIENT_ID") |> String.to_integer(),
       client_secret: System.fetch_env!("STRAVA_CLIENT_SECRET"),
       access_token: System.fetch_env!("STRAVA_ACCESS_TOKEN"),
       redirect_uri: System.fetch_env!("STRAVA_REDIRECT_URI")

# Stripy dev config
config :omega_bravera, :stripe_public_key, System.fetch_env!("STRIPE_PUBLIC_KEY")

config :stripy,
       secret_key: System.fetch_env!("STRIPE_SECRET_KEY")

# Guardian config
config :omega_bravera, OmegaBravera.Guardian,
       secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

# S3 Bucket
config :ex_aws,
       access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
       secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :omega_bravera,
       images_bucket_name: System.fetch_env!("S3_BUCKET"),
       images_cdn_url: System.fetch_env!("CDN_URL")

# FCM setup
config :pigeon, :fcm,
       fcm_default: %{
              key: System.fetch_env!("FCM_KEY")
       }

# Manual activities
config :omega_bravera,
       :enable_manual_activities,
       not is_nil(System.get_env("ENABLE_MANUAL_ACTIVITIES"))
