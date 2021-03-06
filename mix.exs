defmodule OmegaBravera.Mixfile do
  use Mix.Project

  def project do
    [
      app: :omega_bravera,
      version: "1.2.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {OmegaBravera.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_commons, "~> 0.3.0"},
      {:postgrex, "~> 0.15.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.4"},
      {:jason, "~> 1.1"},
      {:bcrypt_elixir, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:guardian, "~> 2.1"},
      {:timex, "~> 3.1"},
      {:strava, "~> 1.0"},
      {:stripy, "~> 1.0"},
      {:decimal, "~> 1.0", override: true},
      {:numbers, "~> 5.1.0"},
      {:edeliver, "~> 1.7.0"},
      {:distillery, "~> 2.1"},
      {:coerce, "~> 1.0.0"},
      {:exvcr, "~> 0.10", only: :test},
      {:sendgrid, "~> 2.0"},
      {:ex_machina, "~> 2.2"},
      {:sched_ex, "~> 1.0"},
      {:csv, "~> 2.0.0"},
      {:mock, "~> 0.3.3", only: :test},
      {:number, "~> 1.0.0"},
      {:slugify, "~> 1.1"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.17"},
      {:sweet_xml, "~> 0.6"},
      {:mogrify, "~> 0.7.0"},
      {:eqrcode, "~> 0.1.6"},
      {:absinthe, "~> 1.5.3"},
      {:absinthe_plug, "~> 1.5.0"},
      {:absinthe_phoenix, "~> 2.0.0"},
      {:absinthe_relay, "~> 1.5.1"},
      {:benchee, "~> 1.0", only: :dev},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_live_view, "~> 0.14.8"},
      {:dataloader, "~> 1.0.7"},
      {:turbo_ecto, "~> 0.5.0"},
      {:turbo_html, "~> 0.2.0"},
      {:oban,
       github: "sorentwo/oban", ref: "f0124f323ee5740471fa4f855f731727ff6ef0bd", override: true},
      {:countries, "~> 1.5"},
      {:pigeon, "~> 1.5.0"},
      {:kadabra, "~> 0.4.4"},
      {:sentry, "~> 8.0"},
      {:geo_postgis, "~> 3.3"},
      {:password_validator, "~> 0.4"},
      {:contex, "~> 0.4.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test --exclude skip"]
    ]
  end
end
