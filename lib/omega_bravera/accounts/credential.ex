defmodule OmegaBravera.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Accounts.{Credential, User}

  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  @create_attrs [
    :password,
    :password_confirmation,
    :reset_token,
    :reset_token_created,
    :user_id
  ]

  schema "credentials" do
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:reset_token, :string, allow_nil: true)
    field(:reset_token_created, :utc_datetime, allow_nil: true)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Credential{} = credential, attrs) do
    credential
    |> cast(attrs, @create_attrs)
    |> validate_required([:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 6)
    |> put_password_hash
  end

  def token_changeset(%Credential{} = credential, attrs) do
    credential
    |> cast(attrs, [:reset_token, :reset_token_created])
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end
