defmodule OmegaBravera.Money do
  @moduledoc """
  The Money context.
  """

  import Ecto.Query, warn: false

  alias OmegaBravera.{Repo, Money.Donation, Money.Tip, Challenges.NGOChal}

  def milestones_donations(%NGOChal{id: challenge_id}) do
    query =
      from(donation in Donation,
        where: donation.ngo_chal_id == ^challenge_id,
        group_by: [donation.status, donation.milestone],
        select: {donation.status, donation.milestone, sum(donation.amount)}
      )

    query
    |> Repo.all()
    # group by milestone
    |> Enum.group_by(&elem(&1, 1), fn {status, _, amount} -> {status, amount} end)
    # turn into hash
    |> Enum.map(fn {k, v} -> {k, Enum.into(v, %{})} end)
    # set default values for milestones without "charged" or "pending" donations
    |> Enum.map(fn {k, v} -> {k, Map.merge(default_milestone_stats(), v)} end)
    # add charged and pending donations into total
    |> Enum.map(fn {k, v} -> {k, Map.put(v, "total", Decimal.add(v["pending"], v["charged"]))} end)
    # hash at the end
    |> Enum.into(%{})
  end

  defp default_milestone_stats, do: %{"charged" => Decimal.new(0), "pending" => Decimal.new(0)}

  # for listing a user's donations

  def get_donations_by_user(user_id) do
    query =
      from(d in Donation,
        where: d.user_id == ^user_id
      )

    Repo.all(query)
  end

  def get_unch_donat_by_ngo_chal(ngo_chal_id) do
    query =
      from(d in Donation,
        where: d.ngo_chal_id == ^ngo_chal_id,
        where: d.status == "pending"
      )

    Repo.all(query)
  end

  def chargeable_donations_for_challenge(%NGOChal{} = challenge) do
    query =
      from(d in Donation,
        where: d.ngo_chal_id == ^challenge.id,
        where: d.status == "pending",
        where:
          d.milestone_distance <
            ^Decimal.to_integer(Decimal.round(challenge.distance_covered, 0, :ceiling))
      )

    Repo.all(query)
  end

  # for charging from strava webhooks

  def get_donations_by_milestone(ngo_chal, milestone_limit) do
    from(d in Donation,
      where:
        d.status == "pending" and d.milestone <= ^milestone_limit and d.ngo_chal_id == ^ngo_chal
    )
    |> Repo.all()
  end

  # get all da donations

  def get_ngo_chal_sponsors(ngo_chal_id) do
    query = from(d in Donation, where: d.ngo_chal_id == ^ngo_chal_id)
    Repo.all(query)
  end

  def list_donations, do: Repo.all(Donation)

  def get_donation!(id), do: Repo.get!(Donation, id)

  def update_donation(%Donation{} = donation, attrs) do
    donation
    |> Donation.changeset(attrs)
    |> Repo.update()
  end

  def delete_donation(%Donation{} = donation), do: Repo.delete(donation)

  def change_donation(%Donation{} = donation), do: Donation.changeset(donation, %{})

  def list_tips, do: Repo.all(Tip)

  def get_tip!(id), do: Repo.get!(Tip, id)

  def create_tip(attrs \\ %{}) do
    %Tip{}
    |> Tip.changeset(attrs)
    |> Repo.insert()
  end

  def update_tip(%Tip{} = tip, attrs) do
    tip
    |> Tip.changeset(attrs)
    |> Repo.update()
  end

  def delete_tip(%Tip{} = tip), do: Repo.delete(tip)

  def change_tip(%Tip{} = tip), do: Tip.changeset(tip, %{})
end
