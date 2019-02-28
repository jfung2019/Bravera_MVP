defmodule OmegaBraveraWeb.EmailSettingsView do
  use OmegaBraveraWeb, :view

  def subscribed?(category_id, user_categories) do
    if Enum.member?(user_categories, category_id) do
      "checked"
    end
  end

  # By default a user subscribed to all email categories.
  # This was done to avoid creating user_email_categories rows for each user.
  def default_categories(user_categories), do: Enum.empty?(user_categories)

  # TODO
  # def is_main_category?(_), do: nil
end
