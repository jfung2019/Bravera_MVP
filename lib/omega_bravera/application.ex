defmodule OmegaBravera.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      OmegaBravera.Repo,
      # Start the endpoint when the application starts
      {Phoenix.PubSub, name: OmegaBravera.PubSub},
      OmegaBravera.PostgresListener,
      OmegaBraveraWeb.Endpoint,
      OmegaBravera.IngestionSupervisor,
      {Absinthe.Subscription, [OmegaBraveraWeb.Endpoint]},
      {Task.Supervisor, name: OmegaBravera.TaskSupervisor},
      {Oban, Application.get_env(:omega_bravera, Oban)}
    ]

    :telemetry.attach_many(
      "oban-logger",
      [[:oban, :started], [:oban, :success], [:oban, :failure]],
      &OmegaBravera.Logger.Oban.handle_event/4,
      []
    )

    :telemetry.attach(
      "ecto-logger",
      [:omega_bravera, :repo, :query],
      &OmegaBravera.Logger.Ecto.handle_event/4,
      %{}
    )

    :telemetry.attach(
      "absinthe-logger",
      [:absinthe, :resolve, :field, :stop],
      &OmegaBravera.Logger.Absinthe.handle_event/4,
      %{}
    )

    children =
      case Application.get_env(:omega_bravera, :env) do
        :prod ->
          [
            pre_registration_challenges_activator(),
            signups_worker_spec(),
            inactive_challenges_spec(),
            challenge_expirer_spec() | children
          ]

        _ ->
          children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OmegaBravera.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    OmegaBraveraWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp pre_registration_challenges_activator do
    %{
      id: "pre_registration_challenges_activator",
      start: {SchedEx, :run_every, [OmegaBravera.Challenges.LiveWorker, :start, [], "* * * * *"]}
    }
  end

  defp signups_worker_spec do
    %{
      id: "daily_digest",
      start:
        {SchedEx, :run_every,
         [OmegaBravera.DailyDigest.Worker, :process_digest, [], "0 22 * * *"]}
    }
  end

  defp inactive_challenges_spec do
    %{
      id: "inactive_finder",
      start:
        {SchedEx, :run_every,
         [OmegaBravera.Challenges.InactivityWorker, :process_inactive_challenges, [], "0 0 * * *"]}
    }
  end

  defp challenge_expirer_spec do
    %{
      id: "challenge_expirer",
      start:
        {SchedEx, :run_every,
         [OmegaBravera.Challenges.ExpirerWorker, :process_expired_challenges, [], "*/1 * * * *"]}
    }
  end
end
