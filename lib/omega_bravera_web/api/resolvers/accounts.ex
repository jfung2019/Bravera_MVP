defmodule OmegaBraveraWeb.Api.Resolvers.Accounts do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Guardian
  alias OmegaBravera.{Accounts, Locations}
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def login(_root, %{email: email, password: password}, _info) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        {:ok, token, _} = Guardian.encode_and_sign(user, %{})
        {:ok, %{user_session: %{token: token, user: user}}}

      {:error, :invalid_password} ->
        {:ok, %{errors: Helpers.transform_errors(%{"password" => gettext("Invalid email and password combo.")})}}

      {:error, :user_does_not_exist} ->
        {:ok, %{errors: Helpers.transform_errors(%{"id" => gettext("Seems you don't have an account, please sign up.")})}}

      {:error, :no_credential} ->
        {:ok, %{errors: Helpers.transform_errors(%{"password" => gettext("Please setup your password using Forgot password.")})}}

    end
  end

  def create_user(_root, %{input: params}, _info) do
    case Accounts.create_credential_user(params) do
      {:ok, user} ->
        Accounts.Notifier.send_user_signup_email(user)
        {:ok, %{user: user}}

      {:error, changeset} ->
        {:ok, %{errors: Helpers.transform_errors(changeset)}}
    end
  end

  def all_locations(_root, _args, _info), do: {:ok, Locations.list_locations()}
end
