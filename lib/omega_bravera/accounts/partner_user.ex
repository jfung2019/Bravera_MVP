defmodule OmegaBravera.Accounts.PartnerUser do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_users" do
    field :first_name, :string
    field :last_name, :string
    field :contact_number, :string
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :email_verified, :boolean, default: false
    field :email_activation_token, :string
    field :reset_token, :string
    field :reset_token_created, :utc_datetime
    field :accept_terms, :boolean, virtual: true, default: false
    belongs_to :location, OmegaBravera.Locations.Location
    has_many :organization_members, OmegaBravera.Accounts.OrganizationMember
    has_many :organizations, through: [:organization_members, :organization]

    timestamps()
  end

  @doc false
  def changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [
      :username,
      :email,
      :password,
      :password_confirmation,
      :email_verified,
      :location_id,
      :first_name,
      :last_name,
      :contact_number,
      :accept_terms
    ])
    |> validate_required([
      :username,
      :email,
      :password,
      :password_confirmation,
      :location_id,
      :first_name,
      :last_name,
      :contact_number
    ])
    |> validate_length(:username, min: 3)
    |> unique_constraint(:email, name: :partner_user_email_index)
    |> EctoCommons.EmailValidator.validate_email(:email)
    |> validate_format(:username, ~r/\A[a-zA-Z0-9_]+\z/,
      message: "only letters and numbers are allowed"
    )
    |> add_email_activation_token()
    |> validate_acceptance(:accept_terms)
    |> unique_constraint(:username)
    |> validate_password()
  end

  def update_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:email, :email_verified, :password, :password_confirmation])
    |> validate_required([:email, :email_verified])
    |> validate_password()
  end

  def password_update_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_password()
  end

  def reset_password_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:reset_token, :reset_token_created])
  end

  def admin_create_changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [
      :username,
      :email,
      :password,
      :password_confirmation,
      :email_verified,
      :location_id,
      :first_name,
      :last_name,
      :contact_number
    ])
    |> validate_required([
      :username,
      :email,
      :password,
      :password_confirmation,
      :location_id,
      :first_name,
      :last_name,
      :contact_number
    ])
    |> validate_length(:username, min: 3)
    |> unique_constraint(:email, name: :partner_user_email_index)
    |> EctoCommons.EmailValidator.validate_email(:email)
    |> validate_format(:username, ~r/\A[a-zA-Z0-9_]+\z/,
      message: "only letters and numbers are allowed"
    )
    |> unique_constraint(:username)
    |> validate_password()
    # no need to verify email if admin created
    |> put_change(:email_verified, true)
  end

  defp validate_password(%{changes: %{password: _}} = changeset) do
    changeset
    |> validate_required([:password, :password_confirmation])
    |> PasswordValidator.validate(:password, password_opt())
    |> validate_confirmation(:password)
    |> put_pass_hash()
  end

  defp validate_password(changeset), do: changeset
end
