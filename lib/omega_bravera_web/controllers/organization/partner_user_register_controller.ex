defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  plug :assign_available_options when action in [:new]

  def new(conn, _params) do
    with %Accounts.PartnerUser{id: partner_user_id} <- Guardian.Plug.current_resource(conn),
         %{account_type: :full} <- Accounts.get_organization_by_partner_user!(partner_user_id) do
      redirect(conn, to: Routes.org_panel_dashboard_path(conn, :index))
    else
      %{account_type: :merchant} ->
        redirect(conn, to: Routes.org_panel_online_offers_path(conn, :index))

      _ ->
        render(conn, "new.html",
          changeset: Accounts.change_organization_member(%Accounts.OrganizationMember{})
        )
    end
  end

  def create(conn, %{"organization_member" => member_params}) do
    case Accounts.create_partner_user_and_organization(member_params) do
      {:ok, _} ->
        conn
        |> put_flash(
          :info,
          "Account created! Please check your inbox and click the link we sent to verify your account email."
        )
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:error, changeset} ->
        conn
        |> assign_available_options(nil)
        |> put_flash(:error, "Error Registering.")
        |> render("new.html", changeset: changeset)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_locations, OmegaBravera.Locations.list_locations())
  end
end
