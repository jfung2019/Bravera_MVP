defmodule OmegaBraveraWeb.EmailSettingsController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Notifications}

  def edit(conn, _) do
    current_user = Guardian.Plug.current_resource(conn)
    all_categories = Notifications.list_email_categories()

    user_categories =
      Notifications.get_user_subscribed_email_categories(current_user.id)
      |> Enum.map(& &1.category.id)

    changeset = Notifications.change_email_category(%Notifications.EmailCategory{})

    render(conn, "edit.html",
      user_categories: user_categories,
      all_categories: all_categories,
      changeset: changeset
    )
  end

  @doc """
    Deletes existing rows and creates new rows for user email subscriptions to groups
    based on choice from UI.

    By default, we do not create rows for each user for email subscriptions and this
    means they _are_ subscribed to all email categories.
  """
  def update(conn, %{"subscribed_categories" => subscribed_categories}) do
    current_user = Guardian.Plug.current_resource(conn)

    subscribed_categories =
      subscribed_categories
      |> to_integers()

    if require_main_category(subscribed_categories) do
      Notifications.delete_and_update_user_email_categories(subscribed_categories, current_user)

      conn
      |> put_flash(:info, "Updated email settings sucessfully.")
      |> redirect(to: Routes.email_settings_path(conn, :edit))
    else
      # To protect vs removing the hidden element for the main category.
      conn
      |> put_flash(
        :error,
        "Cannot unsubscribe from platform notification. Please request account termination from admin@bravera.co"
      )
      |> redirect(to: Routes.email_settings_path(conn, :edit))
    end
  end

  defp to_integers(list), do: Enum.map(list, &String.to_integer/1)

  defp require_main_category(subscribed_categories) do
    main_category = Notifications.get_email_category_by_title("Platform Notifications")

    Enum.member?(subscribed_categories, main_category.id)
  end
end
