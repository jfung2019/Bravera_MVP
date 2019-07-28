defmodule OmegaBraveraWeb.PasswordController do
  use OmegaBraveraWeb, :controller

  require Logger

  alias OmegaBravera.Repo
  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.{User, Credential, Notifier}

  use Timex

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset, action: password_path(conn, :create))
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    credential =
      case email do
        nil ->
          nil

        email ->
          Accounts.get_user_credential(email)
      end

    case credential do
      nil ->
        # search for email in users
        case Repo.get_by(User, email: email) do
          nil ->
            conn
            |> put_flash(:error, "There's no account associated with that email")
            |> redirect(to: password_path(conn, :new))

          user ->
            case Accounts.create_credential_for_existing_strava(%{
                   user_id: user.id,
                   reset_token: random_string(64),
                   reset_token_created: Timex.now()
                 }) do
              {:ok, created_credential} ->
                Notifier.send_password_reset_email(created_credential)

                conn
                |> put_flash(
                  :info,
                  "You will receive a link in your #{email} inbox soon to set your new password."
                )
                |> redirect(to: page_path(conn, :index))

              {:error, reason} ->
                Logger.error(
                  "PasswordController: could not create new credential, reason: #{inspect(reason)}"
                )

                conn
                |> put_flash(:error, "Something went wrong while trying to reset your password.")
                |> redirect(to: password_path(conn, :new))
            end
        end

      credential ->
        case reset_password_token(credential) do
          {:ok, updated_credential} ->
            Notifier.send_password_reset_email(updated_credential)
        end

        conn
        |> put_flash(:info, "You will receive a password reset link in your #{email} inbox soon.")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def edit(conn, %{"reset_token" => token}) do
    credential = Accounts.get_credential_by_token(token)

    case credential do
      nil ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: password_path(conn, :new))

      credential ->
        %{reset_token_created: reset_token_created} = credential

        if expired?(reset_token_created) do
          nullify_token(credential)

          conn
          |> put_flash(:error, "Password reset token expired")
          |> redirect(to: password_path(conn, :new))
        else
          changeset = Accounts.change_credential(%Credential{})

          conn
          |> render("edit.html", changeset: changeset, token: token, credential: credential)
        end
    end
  end

  def update(conn, params) do
    credential =
      params
      |> Map.get("reset_token")
      |> Accounts.get_credential_by_token()

    case credential do
      nil ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: password_path(conn, :new))

      credential ->
        %{reset_token_created: reset_token_created} = credential

        if expired?(reset_token_created) do
          nullify_token(credential)

          conn
          |> put_flash(:error, "Password reset token expired")
          |> redirect(to: password_path(conn, :new))
        else
          case Accounts.update_credential(credential, params["credential"]) do
            {:ok, _response} ->
              nullify_token(credential)

              conn
              |> put_flash(:info, "Password reset successfully!")
              |> redirect(to: page_path(conn, :index))

            {:error, changeset} ->
              conn
              |> render("edit.html",
                changeset: changeset,
                credential: credential,
                token: params["reset_token"]
              )
          end
        end
    end
  end

  defp nullify_token(credential) do
    Accounts.update_credential_token(credential, %{
      reset_token: nil,
      reset_token_created: nil
    })
  end

  # sets the token & sent at in the database for the credential
  defp reset_password_token(credential) do
    token = random_string(64)
    now = DateTime.utc_now()

    credential
    |> Accounts.update_credential_token(%{reset_token: token, reset_token_created: now})
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  defp expired?(datetime), do: Timex.after?(Timex.now(), Timex.shift(datetime, days: 1))
end
