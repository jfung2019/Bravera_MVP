defmodule OmegaBraveraWeb.LiveUserLogin do
  use Phoenix.LiveView

  # alias OmegaBraveraWeb.Router.Helpers, as: Routes
  # alias OmegaBraveraWeb.Endpoint

  alias OmegaBravera.Accounts

  def mount(_session, socket) do
    {:ok, assign(socket, %{
      changeset: Accounts.Login.changeset(%Accounts.Login{}),
      open_modal: false,
      error: nil,
      login_button_disabled?: true
    })}
  end

  def render(assigns), do: OmegaBraveraWeb.LayoutView.render("unauth_nav.html", assigns)

  def handle_event("validate", %{"login" => %{"email" => email, "password" => pass} = params}, socket) do
    changeset =
      %Accounts.Login{}
      |> Accounts.Login.changeset(params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      case Accounts.email_password_auth(email, pass) do
        {:ok, _user} ->
          {:noreply, assign(socket, open_modal: true, login_button_disabled?: changeset.valid?)}

        {:error, :invalid_password} ->
          {:noreply, assign(socket, error: "Invalid email and password combo.", open_modal: true, login_button_disabled?: false)}

        {:error, :user_does_not_exist} ->
          {:noreply, assign(socket, error: "User does not exist in our database.", open_modal: true, login_button_disabled?: false)}
      end
    else
      {:noreply, assign(socket, changeset: changeset, open_modal: true, login_button_disabled?: changeset.valid?)}
    end

  end

  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, open_modal: false)}
end
