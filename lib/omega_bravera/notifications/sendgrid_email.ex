defmodule OmegaBravera.Notifications.SendgridEmail do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Notifications.EmailCategory

  schema "sendgrid_emails" do
    field :sendgrid_id, :string
    belongs_to :category, EmailCategory
    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(sendgrid_email, attrs) do
    sendgrid_email
    |> cast(attrs, [:sendgrid_id, :category_id])
    |> validate_required([:sendgrid_id, :category_id])
    |> unique_constraint(:sendgrid_id)
  end
end
