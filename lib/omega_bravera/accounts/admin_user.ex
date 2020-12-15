defmodule OmegaBravera.Accounts.AdminUser do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  @roles ["super", "partner"]

  schema "admin_users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :role, :string, default: "super"

    timestamps()
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email, :password, :role])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> validate_inclusion(:role, @roles)
    |> put_pass_hash()
  end
end
