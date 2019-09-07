defmodule OmegaBraveraWeb.Api.Resolvers.Accounts do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Guardian
  alias OmegaBravera.{Accounts, Locations}
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def login(root, %{locale: locale} = params, info) do
    case locale do
      "en" -> do_login(root, params, info)
      "zh" -> do_login(root, params, info)
      _ -> {:error, message: gettext("Locale is required to login. Supported locales are: en, zh.")}
    end
  end

  defp do_login(_root, %{email: email, password: password, locale: _locale}, _info) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        {:ok, token, _} = Guardian.encode_and_sign(user, %{})
        {:ok, %{user_session: %{token: token, user: user, user_profile: Accounts.api_user_profile(user.id)}}}

      {:error, :invalid_password} ->
        {:error, message: gettext("Invalid email and password combo.")}

      {:error, :user_does_not_exist} ->
        {:error, message: gettext("Seems you don't have an account, please sign up.")}

      {:error, :no_credential} ->
        {:error, message: gettext("Please setup your password using Forgot password.")}
    end
  end

  def create_user(root, %{input: %{locale: locale}} = params, info) do
    case locale do
      "en" -> do_create_user(root, params, info)
      "zh" -> do_create_user(root, params, info)
      _ -> {:error, message: gettext("Locale is required to signup. Supported locales are: en, zh.")}
    end
  end

  defp do_create_user(_root, %{input: params}, _info) do
    case Accounts.create_credential_user(params) do
      {:ok, user} ->
        Accounts.Notifier.send_user_signup_email(user)
        {:ok, token, _} = Guardian.encode_and_sign(user, %{})
        {:ok, %{user: user, token: token, user_profile: Accounts.api_user_profile(user.id)}}

      {:error, changeset} ->
        {:error, message: "Could not signup", details: Helpers.transform_errors(changeset)}
    end
  end

  def all_locations(_root, _args, _info), do: {:ok, Locations.list_locations()}

  def user_profile(_root, %{user_id: user_id}, %{context: %{current_user: current_user}}) when current_user == user_id, do: {:ok, Accounts.api_user_profile(user_id)}
  def user_profile(_root, _args, _info), do: {:error, "not_authorized"}
end
