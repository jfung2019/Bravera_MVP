defmodule OmegaBravera.Repo do
  use Ecto.Repo, otp_app: :omega_bravera, adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    opts =
      opts
      |> Keyword.put(:url, System.get_env("DATABASE_URL"))
      |> Keyword.put(:ssl, !is_nil(System.get_env("DATABASE_SSL")))
    {:ok, opts}
  end
end
