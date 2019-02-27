defmodule OmegaBravera.Emails.EmailCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Emails.SendgridEmail

  schema "email_categories" do
    field :description, :string
    field :title, :string

    has_many(:sendgrid_emails, SendgridEmail, foreign_key: :category_id)
  end

  @doc false
  def changeset(email_category, attrs) do
    email_category
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
