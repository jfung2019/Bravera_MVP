defmodule OmegaBraveraWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: OmegaBraveraWeb
      import Plug.Conn
      alias OmegaBraveraWeb.Router.Helpers, as: Routes
      import OmegaBraveraWeb.Gettext
      import OmegaBraveraWeb.Controllers.Helpers
      import Phoenix.LiveView.Controller
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/omega_bravera_web/templates",
        namespace: OmegaBraveraWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      alias OmegaBraveraWeb.Router.Helpers, as: Routes
      import OmegaBraveraWeb.ErrorHelpers
      import OmegaBraveraWeb.Gettext
      import OmegaBraveraWeb.ViewHelpers
      import Phoenix.LiveView.Helpers
      import Turbo.HTML
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import OmegaBraveraWeb.Gettext
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView
      import Phoenix.HTML.Link
      alias OmegaBraveraWeb.Router.Helpers, as: Routes
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      alias OmegaBraveraWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
