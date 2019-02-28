defmodule OmegaBraveraWeb.EmailSettingsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Emails}

  def edit(conn, _) do
    current_user = Guardian.Plug.current_resource(conn)
    all_categories = Emails.list_email_categories()
    user_categories =
      Emails.get_user_subscribed_email_categories(current_user.id)
      |> Enum.map(&(&1.category.id))

    changeset = Emails.change_email_category(%Emails.EmailCategory{})
    render(conn, "edit.html", user_categories: user_categories, all_categories: all_categories, changeset: changeset)
  end

  def update(conn, %{"subscribed_categories" => subscribed_categories}) do
    current_user = Guardian.Plug.current_resource(conn)
    subscribed_categories =
      subscribed_categories
      |> to_integers()

    Emails.delete_and_update_user_email_categories(subscribed_categories, current_user)
    conn
    |> put_flash(:info, "Updated email settings sucessfully.")
    |> redirect(to: email_settings_path(conn, :edit))

  end

  defp to_integers(list), do: Enum.map(list ,&(String.to_integer/1))
end


