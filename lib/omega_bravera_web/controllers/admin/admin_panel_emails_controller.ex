defmodule OmegaBraveraWeb.AdminPanelEmailsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Notifications

  def index(conn, params) do
    results =
      Turbo.Ecto.turbo(Notifications.list_sendgrid_emails_query(), params, entry_name: "emails")

    render(conn, "index.html", emails: results.emails, paginate: results.paginate)
  end

  def new(conn, _params) do
    changeset = Notifications.change_sendgrid_email(%Notifications.SendgridEmail{})
    categories = Notifications.list_email_categories()
    render(conn, "new.html", categories: categories, changeset: changeset)
  end

  def create(conn, %{"sendgrid_email" => sendgrid_email_params}) do
    case Notifications.create_sendgrid_email(sendgrid_email_params) do
      {:ok, _sendgrid_email} ->
        conn
        |> put_flash(:info, "Sendgrid Email created successfully.")
        |> redirect(to: Routes.admin_panel_emails_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Notifications.list_email_categories()
        render(conn, "new.html", categories: categories, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    sendgrid_email = Notifications.get_sendgrid_email!(id)
    categories = Notifications.list_email_categories()
    changeset = Notifications.change_sendgrid_email(sendgrid_email)

    render(conn, "edit.html",
      sendgrid_email: sendgrid_email,
      categories: categories,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "sendgrid_email" => sendgrid_email_params}) do
    sendgrid_email = Notifications.get_sendgrid_email!(id)

    case Notifications.update_sendgrid_email(sendgrid_email, sendgrid_email_params) do
      {:ok, _created_sendgrid_email} ->
        conn
        |> put_flash(:info, "Sendgrid Email updated successfully.")
        |> redirect(to: Routes.admin_panel_emails_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Notifications.list_email_categories()
        render(conn, "edit.html", categories: categories, changeset: changeset)
    end
  end
end
