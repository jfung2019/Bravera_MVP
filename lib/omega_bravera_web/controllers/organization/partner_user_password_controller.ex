defmodule OmegaBraveraWeb.PartnerUserPasswordController do
  use OmegaBraveraWeb, :controller
  require Logger
  alias OmegaBravera.{Accounts, Accounts.PartnerUser}

  use Timex

  def new(conn, _params) do
    changeset = Accounts.change_partner_user(%PartnerUser{})

    render(conn, "new.html",
      changeset: changeset,
      action: Routes.partner_user_password_path(conn, :create)
    )
  end

  def create(conn, %{"partner_user" => %{"email" => email}}) do
    case Accounts.get_partner_user_by_email_or_username(email) do
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("There's no account associated with that username or email"))
        |> render("new.html",
          changeset: Accounts.change_partner_user(%PartnerUser{}),
          action: Routes.partner_user_password_path(conn, :create)
        )

      {:ok, partner_user} ->
        Accounts.reset_partner_user_password(partner_user)

        conn
        |> put_flash(
          :info,
          gettext(
            "Password reset link sent. Please check your inbox.",
            email: email
          )
        )
        |> render("new.html",
          changeset: Accounts.change_partner_user(partner_user),
          action: Routes.partner_user_password_path(conn, :create),
          email_sent: true
        )
    end
  end

  def edit(conn, %{"reset_token" => token}) do
    case Accounts.get_partner_user_by_reset_password_token(token) do
      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: Routes.password_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "Password reset token expired")
        |> redirect(to: Routes.partner_user_password_path(conn, :new))

      {:ok, partner_user} ->
        conn
        |> render("edit.html",
          changeset: Accounts.change_partner_user(partner_user),
          token: token,
          partner_user: partner_user
        )
    end
  end

  def update(conn, %{"reset_token" => token, "partner_user" => partner_user_params}) do
    case Accounts.set_partner_user_password(token, partner_user_params) do
      {:ok, _partner_user} ->
        conn
        |> put_flash(:info, "Password reset successfully!")
        |> redirect(to: Routes.partner_user_session_path(conn, :new))

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: Routes.partner_user_password_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "Password reset token expired")
        |> redirect(to: Routes.partner_user_password_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, partner_user} = Accounts.get_partner_user_by_reset_password_token(token)

        conn
        |> render("edit.html",
          changeset: changeset,
          partner_user: partner_user,
          token: token
        )
    end
  end
end
