defmodule OmegaBravera.Accounts.Login do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "login" do
    field(:email, :string)
    field(:password, :string)
  end

  @doc """
  Only used to validate live user login.
  """
  def changeset(login, attrs \\ %{}) do
    login
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, max: 254)
    |> validate_length(:password, min: 6)
  end
end
