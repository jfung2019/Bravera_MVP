defmodule OmegaBraveraWeb.MerchantConstraint do
  alias OmegaBraveraWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn do
      %{assigns: %{organization: %{account_type: :merchant}}} ->
        conn
        |> get_allowed_path()
        |> Enum.map(&String.starts_with?(conn.request_path, &1))
        |> handle_access_constraint(conn)

      _ ->
        conn
    end
  end

  defp get_allowed_path(conn) do
    paths = [
      Routes.org_panel_online_offers_path(conn, :index),
      Routes.org_panel_offline_offers_path(conn, :index),
      Routes.org_panel_offer_vendor_path(conn, :index),
      Routes.org_panel_offer_reward_path(conn, :index),
      "/organization/offers/"
    ]

    if not is_nil(Map.get(conn.assigns, :admin_logged_in)) do
      [Routes.org_panel_dashboard_path(conn, :view_as) | paths]
    else
      paths
    end
  end

  defp handle_access_constraint(paths_allowed, conn) do
    case Enum.member?(paths_allowed, true) do
      true ->
        conn

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: Routes.org_panel_online_offers_path(conn, :index))
    end
  end
end
