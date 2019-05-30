defmodule OmegaBraveraWeb.LiveUserLogin do
  use OmegaBraveraWeb, :live_view

  alias OmegaBravera.Accounts

  def mount(%{csrf: csrf}, socket) do
    {:ok,
    assign(socket, %{
      csrf: csrf,
      changeset: Accounts.Login.changeset(%Accounts.Login{}),
      open_modal: false,
      error: nil,
      login_button_disabled?: false
    })}
  end

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
             error: "Invalid email and password combo.",
             open_modal: true,
             login_button_disabled?: false
           )}

        {:error, :user_does_not_exist} ->
          {:noreply,
           assign(socket,
             changeset: changeset,
             error: "Seems you don't have an account, please sign up.",
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

  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, open_modal: false)}
end
