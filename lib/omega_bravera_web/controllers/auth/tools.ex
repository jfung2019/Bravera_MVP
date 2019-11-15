defmodule OmegaBraveraWeb.Auth.Tools do

  alias OmegaBravera.Accounts

  def nullify_token(credential) do
    Accounts.update_credential_token(credential, %{
      reset_token: nil,
      reset_token_created: nil
    })
  end

  # sets the token & sent at in the database for the credential
  def reset_password_token(credential) do
    token = random_string(64)
    now = DateTime.utc_now()

    credential
    |> Accounts.update_credential_token(%{reset_token: token, reset_token_created: now})
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  def expired?(datetime), do: Timex.after?(Timex.now(), Timex.shift(datetime, days: 1))
end
