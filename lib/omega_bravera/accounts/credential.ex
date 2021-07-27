defmodule OmegaBravera.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Accounts.{Credential, User}

  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  @create_attrs [
    :password,
    :password_confirmation
  ]

  @derive {Phoenix.Param, key: :reset_token}
  schema "credentials" do
    field :password_hash, :string

    field :reset_token, :string, allow_nil: true
    field :reset_token_created, :utc_datetime, allow_nil: true

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Credential{} = credential, attrs \\ %{}) do
    credential
    |> optional_changeset(attrs)
    |> validate_required([:password])
  end

  @doc """
    Used to create credential for an existing Strava User
  """

  def create_credential_for_strava_user(attrs \\ %{}) do
    %Credential{}
    |> cast(attrs, [:user_id, :reset_token, :reset_token_created])
  end

  def token_changeset(%Credential{} = credential, attrs) do
    credential
    |> cast(attrs, [:reset_token, :reset_token_created])
  end

  def optional_changeset(%Credential{} = credential, attrs \\ %{}) do
    credential
    |> cast(attrs, @create_attrs)
    |> validate_confirmation(:password)
    |> PasswordValidator.validate(:password, OmegaBravera.Accounts.Shared.password_opt())
    |> put_password_hash()
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
