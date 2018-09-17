defmodule OmegaBraveraWeb.NGOView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Accounts.User, Challenges.NGOChal}

  def user_full_name(%User{} = user), do: User.full_name(user)

  def nudge_donations_total(%NGOChal{} = challenge) do
    challenge
    |> charged_donations
    |> Enum.filter(&Map.get(&1, :milestone) == 1)
    |> sum_donations
    |> Decimal.to_string
  end

  def milestone_donations_total(%NGOChal{} = challenge) do
    challenge
    |> charged_donations
    |> Enum.filter(&Map.get(&1, :milestone) != 1)
    |> sum_donations
    |> Decimal.to_string
  end

  defp charged_donations(challenge), do: Enum.filter(challenge.donations, &(Map.get(&1, :status) == "charged"))
  defp sum_donations(donations), do: Enum.reduce(donations, Decimal.new(0), fn(donation, acc) -> Decimal.add(acc, donation.amount) end)
end
