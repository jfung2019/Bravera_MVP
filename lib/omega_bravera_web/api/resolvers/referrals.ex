defmodule OmegaBraveraWeb.Api.Resolvers.Referrals do
  import OmegaBraveraWeb.Gettext

  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def create_referral(_info, _params, %{context: %{current_user: %{id: user_id}}}) do
    case OmegaBravera.Referrals.create_referral(%{user_id: user_id}) do
      {:ok, referral} ->
        {:ok, %{referral: referral}}

      {:error, changeset} ->
        {:error,
         message: gettext("Could not create referral."),
         details: Helpers.transform_errors(changeset)}
    end
  end
end
