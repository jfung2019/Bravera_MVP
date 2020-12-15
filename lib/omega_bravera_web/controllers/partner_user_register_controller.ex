defmodule OmegaBraveraWeb.PartnerUserRegisterController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def new(conn, _params), do: render(conn, "new.html")

  def create(conn, register_params) do
    IO.inspect(register_params)
    case Accounts.create_partner_user(register_params) do
      {:ok, _partner_user} ->
        conn
        |> put_flash(:info, "Account created")
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:error, _} ->
        conn
        |> put_flash(:error, "Error Registering")
        |> render("new.html")
    end
  end
end