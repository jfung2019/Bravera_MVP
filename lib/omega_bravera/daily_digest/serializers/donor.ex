defmodule OmegaBravera.DailyDigest.Serializers.Donor do
  alias OmegaBravera.{Repo, Accounts.User}

  def fields, do: [:firstname, :lastname, :pledged_amount]

  def serialize(%User{} = u) do
    user = Repo.preload(u, donations: [ngo_chal: [:ngo]])

    user
    |> Map.take([:firstname, :lastname, :email])
    |> Map.put(:pledged_amount, pledged_amount(user.donations))
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
