defmodule OmegaBraveraWeb.Api.Resolvers.Accounts do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Guardian
  alias OmegaBravera.{Accounts, Locations}
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def login(root, %{locale: locale} = params, info) do
    case locale do
      "en" ->
        do_login(root, params, info)

      "zh" ->
        do_login(root, params, info)

      _ ->
        {:error, message: gettext("Locale is required to login. Supported locales are: en, zh.")}
    end
  end

  defp do_login(_root, %{email: email, password: password, locale: locale}, _info) do
    case Accounts.email_password_auth(email, password) do
      {:ok, user} ->
        {:ok, updated_user} = Accounts.update_user(user, %{locale: locale})
        {:ok, token, _} = Guardian.encode_and_sign(updated_user, %{})

        {
          :ok,
          %{
            user_session: %{
              token: token,
              user: updated_user,
              user_profile: Accounts.api_user_profile(updated_user.id)
            }
          }
        }

      {:error, :invalid_password} ->
        {:error, message: gettext("Invalid email and password combo.")}

      {:error, :user_does_not_exist} ->
        {:error, message: gettext("Seems you don't have an account, please sign up.")}

      {:error, :no_credential} ->
        {:error, message: gettext("Please setup your password using Forgot password.")}
    end
  end

  def create_user(
        root,
        %{
          input: %{
            locale: locale
          }
        } = params,
        info
      ) do
    case locale do
      "en" ->
        do_create_user(root, params, info)

      "zh" ->
        do_create_user(root, params, info)

      _ ->
        {:error, message: gettext("Locale is required to signup. Supported locales are: en, zh.")}
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

  def user_profile(
        _root,
        _args,
        %{
          context: %{
            current_user: %{
              id: id
            }
          }
        }
      ),
      do: {:ok, Accounts.api_user_profile(id)}
end
