defmodule OmegaBravera.Donations.Pledges do
  alias OmegaBravera.{Repo, Money, Challenges, Challenges.NGOChal, Money.Donation}

  # returns a list with the created pledges for the given challenge and stripe customer
  def create(%NGOChal{} = challenge, stripe_customer, donation_params) do
    pledged_charges = pledged_milestones_map(donation_params)

    pledges =
      pledged_charges
      |> Enum.map(&(create_pledge(&1, challenge, donation_params, stripe_customer)))
      |> Enum.filter(&filter_pledge/1)
      |> Enum.map(&elem(&1, 1))

    if length(pledges) == length(Map.keys(pledged_charges)) do
      Challenges.update_ngo_chal(challenge, %{total_pledged: pledged_total(challenge, pledges)})
      {:ok, pledges}
    else
      Enum.each(pledges, &Money.delete_donation/1)
      {:error, :pledge_creation_error}
    end
  end

  def get_kickstarter(pledges) do
    Enum.find(pledges, fn(pledge) -> pledge.milestone == 1 and pledge.milestone_distance == 0 end)
  end

  defp pledged_total(%NGOChal{} = challenge, pledges) do
    Enum.reduce(pledges, Decimal.new(challenge.total_pledged), fn(pledge, acc) -> Decimal.add(acc, pledge.amount) end)
  end

  defp pledged_milestones_map(donation_params) do
    %{
      1 => donation_params["milestone_1"],
      2 => donation_params["milestone_2"],
      3 => donation_params["milestone_3"],
      4 => donation_params["milestone_4"]
    }
  end

  defp create_pledge({step, charge_amount} = milestone, %NGOChal{} = challenge, donation_params, stripe_customer) do
    %Donation{}
    |> Donation.changeset(pledge_attributes(milestone, challenge, donation_params, stripe_customer))
    |> Repo.insert()
  end

  defp pledge_attributes({step, charge_amount}, %NGOChal{} = challenge, %{"currency" => currency, "str_src" => stripe_source, "donor_id" => donor_id}, %{"id" => stripe_customer_id}) do
    %{
      amount: Decimal.new(charge_amount),
      milestone: step,
      milestone_distance: milestone_distance_from_total_distance(challenge, step),
      currency: currency,
      str_src: stripe_source,
      str_cus_id: stripe_customer_id,
      ngo_chal_id: challenge.id,
      ngo_id: challenge.ngo_id,
      user_id: donor_id,
      status: "pending"
    }
  end

  defp pledge_attributes(_, _, _, _) do
    %{}
  end

  defp filter_pledge({:ok, pledge}), do: true
  defp filter_pledge({:error, _}), do: false

  defp milestone_distance_from_total_distance(%NGOChal{} = challenge, step) do
    challenge
    |> NGOChal.milestones_distances()
    |> Map.get("#{step}")
  end
end
