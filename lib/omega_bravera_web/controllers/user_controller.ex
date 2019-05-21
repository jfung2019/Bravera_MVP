defmodule OmegaBraveraWeb.UserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Money, Fundraisers}
  alias OmegaBravera.Accounts.User

  def dashboard(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    render(conn, "dashboard.html", user: user)
  end

  def user_donations(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    %{email: email} = user

    donations = Money.get_donations_by_user_email(email)

    render(conn, "user_donations.html", donations: donations)
  end

  def ngos(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    %{id: user_id} = user

    ngos = Fundraisers.get_ngos_by_user(user_id)

    render(conn, "causes.html", ngos: ngos)
  end

  # Not used
  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  # Not used
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "show.html", user: user)
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
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
          |> put_flash(:info, "Email updated. Please check your inbox now!")
          |> redirect(to: user_path(conn, :show, %{}))
        else
          conn
          |> put_flash(:info, "Updated account settings sucessfully.")
          |> redirect(to: user_path(conn, :show, %{}))
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
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

        conn =
          if is_nil(OmegaBravera.Guardian.Plug.current_resource(conn)) do
            OmegaBravera.Guardian.Plug.sign_in(conn, user)
          else
            conn
          end

        case Accounts.update_user(user, %{email_verified: true}) do
          {:ok, _user} ->
            conn
            |> assign(:welcome_modal, true)
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
end
