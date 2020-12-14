defmodule OmegaBravera.Accounts.PartnerUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_user" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :business_type, :string

    timestamps()
  end

  @doc false
  def changeset(partner_user, attrs) do
    partner_user
    |> cast(attrs, [:email, :password, :business_type])
    |> validate_required([:email, :password, :business_type])
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end
