defmodule OmegaBravera.Accounts.Shared do
  import Ecto.Changeset

  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end

  def add_email_activation_token(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :email_activation_token) do
      nil ->
        changeset
        |> Ecto.Changeset.change(%{
          email_activation_token: gen_token()
        })

      _ ->
        changeset
    end
  end

  def gen_token(length \\ 16),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
