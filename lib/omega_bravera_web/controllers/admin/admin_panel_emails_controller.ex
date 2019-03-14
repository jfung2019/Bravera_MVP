defmodule OmegaBraveraWeb.AdminPanelEmailsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Emails, Repo}

  def index(conn, _params) do
    emails =
      Emails.list_sendgrid_emails()
      |> Repo.preload(:category)

    render(conn, "index.html", emails: emails)
  end

  def new(conn, _params) do
    changeset = Emails.change_sendgrid_email(%Emails.SendgridEmail{})
    categories = Emails.list_email_categories()
    render(conn, "new.html", categories: categories, changeset: changeset)
  end

  def create(conn, %{"sendgrid_email" => sendgrid_email_params}) do
    case Emails.create_sendgrid_email(sendgrid_email_params) do
      {:ok, _sendgrid_email} ->
        conn
        |> put_flash(:info, "Sendgrid Email created successfully.")
        |> redirect(to: admin_panel_emails_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Emails.list_email_categories()
        render(conn, "new.html", categories: categories, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    sendgrid_email = Emails.get_sendgrid_email!(id)
    categories = Emails.list_email_categories()
    changeset = Emails.change_sendgrid_email(sendgrid_email)

    render(conn, "edit.html",
      sendgrid_email: sendgrid_email,
      categories: categories,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "sendgrid_email" => sendgrid_email_params}) do
    sendgrid_email = Emails.get_sendgrid_email!(id)

    case Emails.update_sendgrid_email(sendgrid_email, sendgrid_email_params) do
      {:ok, _created_sendgrid_email} ->
        conn
        |> put_flash(:info, "Sendgrid Email updated successfully.")
        |> redirect(to: admin_panel_emails_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Emails.list_email_categories()
        render(conn, "edit.html", categories: categories, changeset: changeset)
    end
  end
end