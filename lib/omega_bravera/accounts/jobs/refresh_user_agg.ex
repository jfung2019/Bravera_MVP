defmodule OmegaBravera.Accounts.Jobs.RefreshUserAgg do
  use Oban.Worker, queue: :default, max_attempts: 1

  @impl Oban.Worker
  def perform(_args, _job) do
    OmegaBravera.Repo.query!("REFRESH MATERIALIZED VIEW CONCURRENTLY user_agg;")
    :ok
  end
end
