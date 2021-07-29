defmodule OmegaBravera.Accounts.AdminUser do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  @roles ["super", "partner"]

  schema "admin_users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :role, :string, default: "super"
    field :reset_token, :string
    field :reset_token_created, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email, :password, :role])
    |> validate_required([:email, :password])
    |> PasswordValidator.validate(:password, password_opt())
    |> unique_constraint(:email)
    |> EctoCommons.EmailValidator.validate_email(:email)
    |> validate_inclusion(:role, @roles)
    |> put_pass_hash()
  end

  def reset_token_changeset(admin_user) do
    admin_user
    |> cast(%{}, [])
    |> put_change(:reset_token, OmegaBravera.Accounts.Tools.random_string())
    |> put_change(:reset_token_created, DateTime.truncate(Timex.now(), :second))
  end

  def reset_password_changeset(admin_user, attrs) do
    admin_user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> PasswordValidator.validate(:password, password_opt())
    |> validate_confirmation(:password)
    |> put_pass_hash()
    |> nil_reset_token()
  end

  def nil_reset_token(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        changeset
        |> put_change(:reset_token, nil)
        |> put_change(:reset_token_created, nil)

      _ ->
        changeset
    end
  end
end
