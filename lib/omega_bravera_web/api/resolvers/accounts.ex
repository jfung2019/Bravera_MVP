defmodule OmegaBraveraWeb.Api.Resolvers.Accounts do
  import OmegaBraveraWeb.Gettext
  alias OmegaBraveraWeb.Router.Helpers, as: Routes

  require Logger

  alias OmegaBravera.Guardian
  alias OmegaBravera.{Accounts, Locations, Points, Repo}
  alias OmegaBravera.Accounts.Notifier
  alias OmegaBraveraWeb.Api.Resolvers.Helpers
  alias OmegaBraveraWeb.Auth.Tools
  alias OmegaBravera.Accounts.User

  def get_strava_oauth_url(_, _, %{
        context: %{current_user: %{id: _id} = current_user}
      }) do
    case Guardian.encode_and_sign(current_user) do
      {:ok, token, _} ->
        redirect_url =
          Routes.strava_url(OmegaBraveraWeb.Endpoint, :connect_strava_callback_mobile_app, %{
            redirect_to:
              Routes.page_url(OmegaBraveraWeb.Endpoint, :index) <>
                "after_strava_connect/" <> token
          })

        {:ok,
         Strava.Auth.authorize_url!(
           scope: "activity:read_all,profile:read_all",
           redirect_uri: redirect_url
         )}

      {:error, reason} ->
        Logger.error("API: could not encode user, reason: #{inspect(reason)}")
        {:error, message: "Error while connecting to Strava."}
    end
  end

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
    case Accounts.email_password_auth(String.downcase(email), password) do
      {:ok, user} ->
        {:ok, updated_user} = Accounts.update_user(user, %{locale: locale})
        {:ok, token, _} = Guardian.encode_and_sign(updated_user, %{}, ttl: {52, :weeks})

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
        {:error, message: gettext("Invalid email and password combination.")}

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
    case Accounts.create_credential_user(params, deconstuct_and_get_referral(params)) do
      {:ok, user} ->
        if not is_nil(user.referred_by_id) do
          Points.create_bonus_points(%{
            user_id: user.referred_by_id,
            source: "referral",
            value: OmegaBravera.Points.Point.get_inviter_points()
          })

          # Send an email notification to the inviter.
          user_with_points = Accounts.get_user_with_points(user.referred_by_id)
          Notifier.send_bonus_added_to_inviter_email(user_with_points)

          Points.create_bonus_points(%{
            user_id: user.id,
            source: "referral",
            value: Decimal.div(OmegaBravera.Points.Point.get_inviter_points(), 2)
          })
        end

        Accounts.Notifier.send_user_signup_email(user, "/open-app")
        {:ok, token, _} = Guardian.encode_and_sign(user, %{})
        {:ok, %{user: user, token: token, user_profile: Accounts.api_user_profile(user.id)}}

      {:error, changeset} ->
        {:error, message: "Could not signup", details: Helpers.transform_errors(changeset)}
    end
  end

  defp deconstuct_and_get_referral(%{referral_token: token}) when not is_nil(token) do
    if String.length(token) > 0 do
      token
      |> String.trim()
      |> String.split("_")
      |> List.last()
      |> OmegaBravera.Referrals.get_referral_by_token()
    else
      nil
    end
  end

  defp deconstuct_and_get_referral(_), do: nil

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

  def save_settings(_, %{input: user_params}, %{
        context: %{current_user: %{id: id} = current_user}
      }) do
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

  def verify_reset_token(_, %{reset_token: reset_token}, _) do
    case Accounts.get_credential_by_token(reset_token) do
      nil ->
        {:error, message: "Code does not exist."}

      credential ->
        %{reset_token_created: reset_token_created} = credential

        if Tools.expired?(reset_token_created) do
          Tools.nullify_token(credential)
          {:error, message: "Password reset code expired"}
        else
          {:ok, %{status: "OK"}}
        end
    end
  end

  def send_reset_password_code(_, %{email: email}, _) do
    email = String.downcase(email)
    credential =
      case email do
        nil ->
          nil

        email ->
          Accounts.get_user_credential(email)
      end

    case credential do
      nil ->
        # search for email in users
        case Repo.get_by(User, email: email) do
          nil ->
            {:error, message: "There's no account associated with that email"}

          user ->
            case Accounts.create_credential_for_existing_strava(%{
                   user_id: user.id,
                   reset_token: Tools.random_string(),
                   reset_token_created: Timex.now()
                 }) do
              {:ok, created_credential} ->
                Notifier.send_app_password_reset_email(created_credential)

                {:ok,
                 %{
                   status:
                     "You will receive a link in your #{email} inbox soon to set your new password."
                 }}

              {:error, reason} ->
                Logger.error(
                  "API Password Recovery: could not create new credential, reason: #{
                    inspect(reason)
                  }"
                )

                {:error, message: "Something went wrong while trying to reset your password."}
            end
        end

      credential ->
        case Tools.reset_password_token(credential) do
          {:ok, updated_credential} ->
            Notifier.send_app_password_reset_email(updated_credential)

            {:ok,
             %{status: "You will receive a password reset link in your #{email} inbox soon."}}
        end
    end
  end

  def forgot_password_change_password(
        _,
        %{
          reset_token: reset_token,
          password: password,
          password_confirm: password_confirmation
        },
        _context
      ) do
    credential = Accounts.get_credential_by_token(reset_token)

    case credential do
      nil ->
        {:error, message: "Invalid reset code"}

      credential ->
        %{reset_token_created: reset_token_created} = credential

        if Tools.expired?(reset_token_created) do
          Tools.nullify_token(credential)

          {:error, message: "Password reset code expired"}
        else
          case Accounts.update_credential(credential, %{
                 password: password,
                 password_confirmation: password_confirmation
               }) do
            {:ok, _response} ->
              Tools.nullify_token(credential)
              {:ok, %{status: "Password reset successfully!"}}

            {:error, changeset} ->
              Logger.error(
                "API Password Recovery: could not update credential, reason: #{
                  inspect(changeset.errors)
                }"
              )

              {:error,
               message: "Something went wrong while trying to change your password.",
               details: Helpers.transform_errors(changeset)}
          end
        end
    end
  end

  def delete_user_pictures(_, _, %{context: %{current_user: %{id: _user_id} = current_user}}) do
    {:ok, %{status: Accounts.delete_user_profile_pictures(current_user)}}
  end

  def profile_picture_upload(_, %{picture: %{mime_type: type, name: name}}, _context) do
    file_path = Path.join(["profile_pictures", Ecto.UUID.generate() <> Path.extname(name)])
    {:ok, upload_url, file_url} = OmegaBravera.UploadManager.presigned_url(file_path, name, type)
    {:ok, %{upload_url: upload_url, file_url: file_url}}
  end

  def profile_picture_update(_, %{picture_url: url}, %{
        context: %{current_user: %{id: user_id} = current_user}
      }) do
    case Accounts.update_user(current_user, %{profile_picture: url}) do
      {:ok, _updated_user} ->
        {:ok, Accounts.get_user_with_account_settings(user_id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Could not save settings", details: Helpers.transform_errors(changeset)}
    end
  end
end
