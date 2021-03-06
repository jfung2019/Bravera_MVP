defmodule OmegaBravera.Notifications.EmailCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Notifications.SendgridEmail

  schema "email_categories" do
    field :description, :string
    field :title, :string

    field :permitted, :boolean, virtual: true

    has_many :sendgrid_emails, SendgridEmail, foreign_key: :category_id
  end

  @doc false
  def changeset(email_category, attrs) do
    email_category
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
