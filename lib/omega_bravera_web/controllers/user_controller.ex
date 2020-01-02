defmodule OmegaBraveraWeb.UserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Locations}
  plug(:assign_options when action in [:edit, :new, :update])

  def dashboard(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    render(conn, "dashboard.html", user: user)
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "show.html", user: user)
  end

  def show_trackers(conn, _),
    do:
      render(conn, "trackers.html",
        user: Guardian.Plug.current_resource(conn),
        redirect_to: user_path(conn, :show_trackers)
      )

  def edit(conn, _) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user_with_account_settings(user_id)
    changeset = Accounts.change_user(user)

    render(conn, "edit.html",
      user: user,
      changeset: changeset,
      locations: Locations.list_locations()
    )
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, updated_user} ->
        if not is_nil(updated_user.email) and
             updated_user.email_activation_token != user.email_activation_token and
             updated_user.email_verified == false do
          Accounts.Notifier.send_user_signup_email(updated_user, redirect_path(conn))

          conn
          |> put_flash(:info, gettext("Email updated. Please check your inbox now!"))
          |> redirect(to: user_path(conn, :edit, %{}))
        else
          conn
          |> put_flash(:info, gettext("Updated account settings successfully."))
          |> redirect(to: user_path(conn, :edit, %{}))
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          user: user,
          changeset: changeset,
          locations: Locations.list_locations()
        )
    end
  end

  def activate_email(conn, %{"email_activation_token" => email_activation_token} = params) do
    user = Accounts.get_user_by_token(email_activation_token)

    redirect_path =
      case not is_nil(Map.get(params, "redirect_to")) do
        true ->
          params["redirect_to"]

        false ->
          redirect_path(conn)
      end

    case user do
      nil ->
        conn
        |> put_flash(
          :error,
          "Invalid email activation link. Please check your link in your email again."
        )
        |> redirect(to: "/")

      user ->
        case Accounts.update_user(user, %{email_verified: true}) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "Email activated!")
            |> redirect(to: redirect_path)

          {:error, _} ->
            conn
            |> put_flash(:error, "Could not activate your email. Please contact admin@bravera.co")
            |> redirect(to: "/")
        end
    end
  end

  defp redirect_path(conn) do
    after_email_verify =
      Plug.Conn.fetch_cookies(conn)
      |> Map.get(:cookies)
      |> Map.get("after_email_verify")

    case after_email_verify do
      nil ->
        page_path(conn, :index)

      path ->
        path
    end
  end

  defp assign_options(conn, _opts) do
    conn
    |> assign(:gender_options, Accounts.Setting.gender_options())
    |> assign(:weight_list, Accounts.Setting.weight_list())
    |> assign(:weight_fraction_list, Accounts.Setting.weight_fraction_list())
  end
end
