defmodule OmegaBraveraWeb.LiveUserSignup do
  use OmegaBraveraWeb, :live_view

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  alias OmegaBravera.Accounts

  def mount(session, socket) do
    {:ok,
     assign(socket, %{
       csrf: session[:csrf],
       changeset: Accounts.change_credential_user(%Accounts.User{}),
       open_modal: false,
       signup_ok?: false,
       signup_button_disabled?: false
     })}
  end

  def render(assigns), do: OmegaBraveraWeb.UserSessionView.render("signup_modal.html", assigns)

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      Accounts.change_credential_user(%Accounts.User{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset, open_modal: true, signup_button_disabled?: changeset.valid?)}
  end

  def handle_event("signup", %{"user" => params}, socket) do
    case Accounts.create_credential_user(params) do
      {:ok, user} ->
        Accounts.Notifier.send_user_signup_email(user, Routes.user_path(Endpoint, :show, %{}))

        {:noreply, assign(socket, signup_ok?: true, open_modal: true, signup_button_disabled?: true)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, open_modal: true, signup_button_disabled?: changeset.valid?)}
    end
  end

  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, open_modal: false)}
end
