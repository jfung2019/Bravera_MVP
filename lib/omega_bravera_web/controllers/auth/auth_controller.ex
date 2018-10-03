defmodule BraveraWeb.AuthController do
  use OmegaBraveraWeb, :controller
  # NOTE OAuth specific auth funcs have their own controllers, eg: StravaController

  # This controller is for email/pass + login form
  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Guardian

  def index(conn, _params) do
    cond do
      Guardian.Plug.current_resource(conn) ->
        conn
        |> redirect(to: user_path(conn, :dashboard))

      true ->
        changeset = Accounts.change_user(%User{})
        render(conn, "register.html", changeset: changeset)
    end
  end

  def create(conn, params) do
    case Accounts.create_credentialed_user(params) do
      {:ok, result} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> Guardian.Plug.sign_in(result.user)
        |> redirect(to: "/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "Error registering.")
        |> redirect(to: "/")
    end
  end

  def email_login(conn, email, password) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: "/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: "/")
    end
  end

  def token_sign_in(email, password) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        Guardian.encode_and_sign(user)

      _ ->
        {:error, "unauthorized"}
    end
  end
end
