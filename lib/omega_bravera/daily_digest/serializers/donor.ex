defmodule OmegaBravera.DailyDigest.Serializers.Donor do
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint
  alias OmegaBravera.{Repo, Accounts.User}

  def fields, do: [:firstname, :lastname, :challenge_urls, :pledged_amount]

  def serialize(%User{} = u) do
    user = Repo.preload(u, donations: [ngo_chal: [:ngo]])

    user
    |> Map.take([:firstname, :lastname, :email])
    |> Map.put(:challenge_urls, challenges_url(user.donations))
    |> Map.put(:pledged_amount, pledged_amount(user.donations))
  end

  defp challenges_url(donations) do
    donations
    |> Enum.group_by(fn dn -> dn.ngo_chal_id end, fn dn -> dn.ngo_chal end)
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(&challenge_url/1)
    |> Enum.join(", ")
  end

  defp challenge_url(challenge) do
    Routes.ngo_ngo_chal_url(Endpoint, :show, challenge.ngo.slug, challenge.slug)
  end

  defp pledged_amount(donations) do
    amount =
      donations
      |> Enum.reduce(Decimal.new(0), fn dn, acc -> Decimal.add(acc, Map.get(dn, :amount)) end)
      |> Decimal.to_string()

    case Enum.take(donations, 1) do
      [] ->
        "$0"

      [%{currency: currency}] ->
        "$#{amount} #{String.upcase(currency)}"
    end
  end
end
