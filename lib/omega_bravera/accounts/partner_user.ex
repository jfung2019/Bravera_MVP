defmodule OmegaBravera.Accounts.PartnerUser do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :business_type, :string
    field :email_verified, :boolean, default: false
    field :email_activation_token, :string
    field :reset_token, :string
    field :reset_token_created, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:username, :email, :password, :business_type, :email_verified])
    |> validate_required([:username, :email, :password, :business_type])
    |> validate_length(:username, min: 3)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> add_email_activation_token()
    |> validate_password()
  end

  def update_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:email, :business_type, :email_verified, :password])
    |> validate_required([:email, :business_type, :email_verified])
    |> validate_password()
  end

  def reset_password_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:reset_token, :reset_token_created])
  end

  defp validate_password(%{changes: %{password: _}} = changeset) do
    changeset
    |> put_pass_hash()
    |> validate_length(:password, min: 6, max: 100)
  end

  defp validate_password(changeset), do: changeset
end
