defmodule OmegaBravera.Guardian do
  use Guardian, otp_app: :omega_bravera

  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.{User, AdminUser}

  def subject_for_token(%User{id: id}, _claims), do: {:ok, "user:#{id}"}
  def subject_for_token(%AdminUser{id: id}, _claims), do: {:ok, "admin_user:#{id}"}
  def subject_for_token(_resource, _claims), do: {:error, :reason_for_error}

  def resource_from_claims(%{"sub" => "user:" <> id}),
    do: {:ok, Accounts.get_user_with_everything!(id)}

  def resource_from_claims(%{"sub" => "admin_user:" <> id}),
    do: {:ok, Accounts.get_admin_user!(id)}

  def resource_from_claims(_claims), do: {:error, :reason_for_error}
end
