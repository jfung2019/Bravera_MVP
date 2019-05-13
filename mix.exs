defmodule OmegaBravera.Mixfile do
  use Mix.Project

  def project do
    [
      app: :omega_bravera,
      version: "1.2.0",
      elixir: "~> 1.7",
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
      extra_applications: [:logger, :runtime_tools, :sendgrid]
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
      {:phoenix, "~> 1.4.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 1.0"},
      {:plug, "~> 1.7"},
      {:jason, "~> 1.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:guardian, "~> 1.0"},
      {:timex, "~> 3.1"},
      {:bamboo, "~> 0.8"},
      {:strava, "~> 0.7"},
      {:stripy, "~> 1.0"},
      {:decimal, "~> 1.0", override: true},
      {:numbers, "~> 5.1.0"},
      {:edeliver, "~> 1.6.0"},
      {:distillery, "~> 2.0"},
      {:coerce, "~> 1.0.0"},
      {:exvcr, "~> 0.10", only: :test},
      {:sendgrid, "~> 1.8.0"},
      {:ex_machina, "~> 2.2"},
      {:sched_ex, "~> 1.0"},
      {:csv, "~> 2.0.0"},
      {:mock, "~> 0.3.3", only: :test},
      {:number, "~> 1.0.0"},
      {:slugify, "~> 1.1"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:uuid, "~> 1.1"},
      {:mogrify, "~> 0.7.0"},
      {:eqrcode, "~> 0.1.6"}
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
