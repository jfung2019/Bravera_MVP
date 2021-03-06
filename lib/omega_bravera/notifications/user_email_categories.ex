defmodule OmegaBravera.Notifications.UserEmailCategories do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Notifications.EmailCategory, Accounts.User}

  schema "user_email_categories" do
    belongs_to :user, User
    belongs_to :category, EmailCategory
    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(user_email_categories, attrs) do
    user_email_categories
    |> cast(attrs, [:category_id, :user_id])
    |> validate_required([:category_id, :user_id])
    |> unique_constraint(:category_id_user_id)
  end
end
