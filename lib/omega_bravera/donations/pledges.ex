defmodule OmegaBravera.Donations.Pledges do
  alias OmegaBravera.{Repo, Money, Challenges, Challenges.NGOChal, Money.Donation}

  # returns a list with the created pledges for the given challenge and stripe customer
  def create(%NGOChal{type: "PER_MILESTONE"} = challenge, stripe_customer, donation_params) do
    pledged_charges = pledged_milestones_map(donation_params)

    pledges =
      pledged_charges
      |> Enum.map(&create_pledge(&1, challenge, donation_params, stripe_customer))
      |> Enum.filter(&filter_pledge/1)
      |> Enum.map(&elem(&1, 1))

    if length(pledges) == length(Map.keys(pledged_charges)) do
      Challenges.update_ngo_chal(challenge, %{
        self_donated: self_donated(challenge, donation_params)
      })

      {:ok, pledges}
    else
      Enum.each(pledges, &Money.delete_donation/1)
      {:error, :pledge_creation_error}
    end
  end

  def create(%NGOChal{type: "PER_KM"} = challenge, stripe_customer, donation_params) do
    case create_pledge(challenge, donation_params, stripe_customer) do
      {:ok, pledge} ->
        Challenges.update_ngo_chal(challenge, %{
          self_donated: self_donated(challenge, donation_params)
        })

        {:ok, [pledge]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_kickstarter(pledges) do
    Enum.find(pledges, fn pledge -> pledge.milestone == 1 and pledge.milestone_distance == 0 end)
  end

  defp pledged_milestones_map(donation_params) do
    %{
      1 => donation_params["milestone_1"],
      2 => donation_params["milestone_2"],
      3 => donation_params["milestone_3"],
      4 => donation_params["milestone_4"]
    }
  end

  defp create_pledge(
         {step, charge_amount} = milestone,
         %NGOChal{type: "PER_MILESTONE"} = challenge,
         donation_params,
         stripe_customer
       ) do
    attrs = pledge_attributes(milestone, challenge, donation_params, stripe_customer)

    %Donation{}
    |> Donation.changeset(attrs)
    |> Repo.insert()
  end

  defp pledge_attributes(
         {step, charge_amount},
         %NGOChal{type: "PER_MILESTONE"} = challenge,
         %{"currency" => currency, "str_src" => stripe_source, "donor_id" => donor_id},
         %{"id" => stripe_customer_id}
       ) do
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

  defp create_pledge(%NGOChal{type: "PER_KM"} = challenge, donation_params, stripe_customer) do
    attrs = pledge_attributes(challenge, donation_params, stripe_customer)

    %Donation{}
    |> Donation.changeset(attrs)
    |> Repo.insert()
  end

  defp pledge_attributes(
         %NGOChal{type: "PER_KM"} = challenge,
         %{
           "currency" => currency,
           "str_src" => stripe_source,
           "donor_id" => donor_id,
           "pledge_per_km" => pledge_per_km
         },
         %{"id" => stripe_customer_id}
       ) do
    %{
      amount: Decimal.new(pledge_per_km),
      km_distance: challenge.distance_target,
      currency: currency,
      str_src: stripe_source,
      str_cus_id: stripe_customer_id,
      ngo_chal_id: challenge.id,
      ngo_id: challenge.ngo_id,
      user_id: donor_id,
      status: "pending"
    }
  end

  defp pledge_attributes(_, _, _) do
    %{}
  end

  defp pledge_attributes(_, _, _, _) do
    %{}
  end

  defp self_donated(challenge, donation_params) do
    challenge.self_donated || challenge.user_id == donation_params["donor_id"]
  end

  defp filter_pledge({:ok, pledge}), do: true
  defp filter_pledge({:error, _}), do: false

  defp milestone_distance_from_total_distance(%NGOChal{} = challenge, step) do
    challenge
    |> NGOChal.milestones_distances()
    |> Map.get("#{step}")
  end
end
