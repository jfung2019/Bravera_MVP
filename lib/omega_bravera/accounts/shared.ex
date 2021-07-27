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
          email_activation_token: gen_user_activate_email_token()
        })

      _ ->
        changeset
    end
  end

  def gen_token(length \\ 16),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)

  def gen_user_activate_email_token(length \\ 6) do
    {code, _} =
      :crypto.strong_rand_bytes(length)
      |> Base.encode16()
      |> Integer.parse(16)

    to_string(code) |> binary_part(0, length)
  end

  def password_opt do
    [
      length: [min: 8, messages: [too_short: "Password has to be as least 8 characters long."]],
      character_set: [
        upper_case: [1, :infinity],
        special: [1, :infinity]
      ]
    ]
  end
end
