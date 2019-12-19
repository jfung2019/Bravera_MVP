defmodule OmegaBraveraWeb.Api.Resolvers.Referrals do
  import OmegaBraveraWeb.Gettext

  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def create_referral(_info, _params, %{context: %{current_user: %{id: user_id} = user}}) do
    case OmegaBravera.Referrals.get_or_create_referral(user_id) do
      {:ok, referral} ->
        {:ok, %{referral: construct_referral(user, referral)}}

      {:error, changeset} ->
        {:error,
         message: gettext("Could not create referral."),
         details: Helpers.transform_errors(changeset)}
    end
  end

  defp construct_referral(%{firstname: fname, lastname: lname}, referral) do
    prefix = String.upcase(fname) <> String.first(lname)
    %{referral | token: String.upcase(prefix) <> "_" <> referral.token}
  end
end
