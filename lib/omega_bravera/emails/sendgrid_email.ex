defmodule OmegaBravera.Emails.SendgridEmail do
  use Ecto.Schema
  import Ecto.Changeset


  schema "sendgrid_emails" do
    field :sendgrid_id, :string
    field :category_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sendgrid_email, attrs) do
    sendgrid_email
    |> cast(attrs, [:sendgrid_id, :category_id])
    |> validate_required([:sendgrid_id, :category_id])
  end
end
