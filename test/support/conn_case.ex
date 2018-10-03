defmodule OmegaBraveraWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  import OmegaBravera.Factory

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import OmegaBraveraWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint OmegaBraveraWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(OmegaBravera.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(OmegaBravera.Repo, {:shared, self()})
    end

    conn = Phoenix.ConnTest.build_conn()

    {conn, user} =
      if tags[:authenticated] do
        user = insert(:user)
        {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

        {Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token), user}
      else
        {conn, nil}
      end

    {:ok, conn: conn, user: user}
  end
end
