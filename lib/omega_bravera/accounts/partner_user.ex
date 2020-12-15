defmodule OmegaBravera.Accounts.PartnerUser do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_user" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :business_type, :string
    field :email_verified, :boolean, default: false
    field :email_activation_token, :string

    timestamps()
  end

  @doc false
  def changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:email, :password, :business_type, :email_verified])
    |> validate_required([:email, :password, :business_type])
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> put_pass_hash()
    |> add_email_activation_token()
  end

  def update_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:email, :business_type, :email_verified])
    |> validate_required([:email, :business_type, :email_verified])
  end
end
