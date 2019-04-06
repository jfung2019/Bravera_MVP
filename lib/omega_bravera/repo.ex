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
      |> Keyword.put(:prepare, String.to_existing_atom(System.get_env("git st") || "named"))
      |> Keyword.put(:ssl, !is_nil(System.get_env("DATABASE_SSL")))
      |> Keyword.put(:pool_size, String.to_integer(System.get_env("POOL_SIZE") || "20"))
    {:ok, opts}
  end
end
