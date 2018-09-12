defmodule OmegaBravera.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      #Challenges.InactivityWorker cron schedule
      %{id: "signups_digest", start: {SchedEx, :run_every, [OmegaBravera.Accounts.SignupsTrackingWorker, :process_signups, [], "0 0 * * *"]}},
      %{id: "inactive_finder", start: {SchedEx, :run_every, [OmegaBravera.Challenges.InactivityWorker, :process_inactive_challenges, [], "15 0 * * *"]}},
      %{id: "challenge_expirer", start: {SchedEx, :run_every, [OmegaBravera.Challenges.ExpirerWorker, :process_expired_challenges, [], "*/1 * * * *"]}},

      # Start the Ecto repository
      supervisor(OmegaBravera.Repo, []),
      # Start the endpoint when the application starts
      supervisor(OmegaBraveraWeb.Endpoint, []),
      # Start your own worker by calling: OmegaBravera.Worker.start_link(arg1, arg2, arg3)
      # worker(OmegaBravera.Worker, [arg1, arg2, arg3]),
    ]

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
end
