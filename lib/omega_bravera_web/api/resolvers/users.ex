defmodule OmegaBraveraWeb.Api.Resolvers.Users do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def authenticate(_root, %{email: email, password: password}, _info) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        {:ok, token, _} = Guardian.encode_and_sign(user, %{})
        {:ok, token}

      {:error, :invalid_password} -> {:error, gettext("Invalid email and password combo.")}
      {:error, :user_does_not_exist} -> {:error, gettext("Seems you don't have an account, please sign up.")}
      {:error, :no_credential} -> {:error, gettext("Please setup your password using Forgot password.")}
    end
  end
end
