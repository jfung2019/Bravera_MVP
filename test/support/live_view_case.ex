defmodule OmegaBraveraWeb.LiveViewCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest
      alias OmegaBraveraWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint OmegaBraveraWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(OmegaBravera.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(OmegaBravera.Repo, {:shared, self()})
    end

    :ok
  end
end
