defmodule OmegaBraveraWeb.Api.Resolvers.Accounts do
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.Guardian
  alias OmegaBravera.{Accounts, Locations, Points}
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
    referral =
      if Map.has_key?(params, :referral_token) do
        OmegaBravera.Referrals.get_referral_by_token(params.referral_token)
      else
        nil
      end

    case Accounts.create_credential_user(params, referral) do
      {:ok, user} ->
        if not is_nil(user.referred_by_id) do
          Points.create_bonus_points(%{
            user_id: user.referred_by_id,
            source: "referral",
            value: OmegaBravera.Points.Point.get_points_per_km()
          })

          Points.create_bonus_points(%{
            user_id: user.id,
            source: "referral",
            value: Decimal.div(OmegaBravera.Points.Point.get_points_per_km(), 2)
          })
        end

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

  def get_leaderboard(_root, _args, _info),
    do:
      {:ok,
       %{
         this_week: Accounts.api_get_leaderboard_this_week(),
         all_time: Accounts.api_get_leaderboard_all_time()
       }}

  def get_user_with_settings(_root, _args, %{context: %{current_user: %{id: id}}}) do
    case Accounts.get_user_with_account_settings(id) do
      nil ->
        {:error, message: "Could not find user"}

      user_with_settings ->
        {:ok, user_with_settings}
    end
  end

  def save_settings(_, %{input: user_params}, %{context: %{current_user: %{id: id} = current_user}}) do
    current_user = OmegaBravera.Repo.preload(current_user, [:setting, :credential])

    case Accounts.update_user(current_user, user_params) do
      {:ok, updated_user} ->
        if not is_nil(updated_user.email) and
             updated_user.email_activation_token != current_user.email_activation_token and
             updated_user.email_verified == false do
          # TODO: Email was updated. Should display verify your email in app -Sherief
          Accounts.Notifier.send_user_signup_email(updated_user, "/")
        end

        {:ok, Accounts.get_user_with_account_settings(id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Could not save settings", details: Helpers.transform_errors(changeset)}
    end
  end
end
