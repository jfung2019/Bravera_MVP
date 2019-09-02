defmodule OmegaBraveraWeb.LiveUserLogin do
  use OmegaBraveraWeb, :live_view

  alias OmegaBravera.Accounts

  def mount(
        %{
          csrf: csrf,
          redirect_uri: redirect_uri,
          add_team_member_redirect_uri: add_team_member_redirect_uri
        },
        socket
      ) do
    {:ok,
     assign(socket, %{
       csrf: csrf,
       changeset: Accounts.Login.changeset(%Accounts.Login{}),
       open_modal: false,
       error: nil,
       login_button_disabled?: false,
       redirect_uri: redirect_uri,
       add_team_member_redirect_uri: add_team_member_redirect_uri
     })}
  end

  def mount(%{add_team_member_redirect_uri: add_team_member_redirect_uri}, socket),
    do: {:stop, redirect(socket, to: add_team_member_redirect_uri)}

  def mount(%{redirect_uri: redirect_uri}, socket),
    do: {:stop, redirect(socket, to: redirect_uri)}

  def mount(_session, socket), do: {:stop, redirect(socket, to: "/")}

  def render(assigns), do: OmegaBraveraWeb.UserSessionView.render("login_modal.html", assigns)

  def handle_event(
        "validate",
        %{"session" => %{"email" => email, "password" => pass} = params},
        socket
      ) do
    changeset =
      %Accounts.Login{}
      |> Accounts.Login.changeset(params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      case Accounts.email_password_auth(email, pass) do
        {:ok, _user} ->
          {:noreply,
           assign(socket,
             changeset: changeset,
             error: nil,
             open_modal: true,
             login_button_disabled?: changeset.valid?
           )}

        {:error, :invalid_password} ->
          {:noreply,
           assign(socket,
             changeset: changeset,
             error: gettext("Invalid email and password combo."),
             open_modal: true,
             login_button_disabled?: false
           )}

        {:error, :user_does_not_exist} ->
          {:noreply,
           assign(socket,
             changeset: changeset,
             error: gettext("Seems you don't have an account, please sign up."),
             open_modal: true,
             login_button_disabled?: false
           )}

        {:error, :no_credential} ->
          {:noreply,
           assign(socket,
             changeset: changeset,
             error: gettext("Please setup your password using Forgot password."),
             open_modal: true,
             login_button_disabled?: false
           )}
      end
    else
      {:noreply,
       assign(socket,
         changeset: changeset,
         open_modal: true,
         login_button_disabled?: changeset.valid?
       )}
    end
  end

  # TODO: see why we are getting %{} for params in prod with some users
  def handle_event("validate", _, socket), do: {:noreply, socket}

  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, open_modal: false)}
end
