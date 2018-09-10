defmodule OmegaBravera.Money do
  @moduledoc """
  The Money context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias OmegaBravera.{Repo, Money.Donation, Money.Tip, Challenges, Challenges.NGOChal}

  # getting milestones

  def get_charged_milestones(ngo_chal_id, milestone) do
    query = from d in Donation,
      where: d.milestone == ^milestone,
      where: d.ngo_chal_id == ^ngo_chal_id,
      where: d.status == "charged",
      select: sum(d.amount)

    Repo.all(query)
  end

  def get_uncharged_milestones(ngo_chal_id, milestone) do
    query = from d in Donation,
      where: d.milestone == ^milestone,
      where: d.ngo_chal_id == ^ngo_chal_id,
      where: d.status == "pending",
      select: sum(d.amount)

    Repo.all(query)
  end

  # for listing a user's donations

  def get_donations_by_user(user_id) do
    query = from d in Donation,
      where: d.user_id == ^user_id

    Repo.all(query)
  end

  def get_unch_donat_by_ngo_chal(ngo_chal_id) do
    query = from d in Donation,
      where: d.ngo_chal_id == ^ngo_chal_id,
      where: d.status == "pending"

    Repo.all(query)
  end

  def chargeable_donations_for_challenge(%NGOChal{} = challenge) do
    query = from d in Donation,
      where: d.ngo_chal_id == ^challenge.id,
      where: d.status == "pending",
      where: d.milestone_distance < ^Decimal.to_integer(Decimal.round(challenge.distance_covered, 0, :ceiling))

    Repo.all(query)
  end

  # for charging from strava webhooks

  def get_donations_by_milestone(ngo_chal, milestone_limit) do
    query = from d in Donation,
      where: d.status == "pending" and d.milestone <= ^milestone_limit and d.ngo_chal_id == ^ngo_chal

    Repo.all(query)
  end

  # get all da donations

  def get_ngo_chal_sponsors(ngo_chal_id) do
    query = from d in Donation, where: d.ngo_chal_id == ^ngo_chal_id
    Repo.all(query)
  end

  def list_donations do
    Repo.all(Donation)
  end

  def get_donation!(id), do: Repo.get!(Donation, id)

  def create_donation(rel_params, params) do
    %{user_id: user_id, ngo_chal_id: ngo_chal_id, ngo_id: ngo_id} = rel_params

    ngo_chal = Challenges.get_ngo_chal!(ngo_chal_id)

    %{total_pledged: total_pledged} = ngo_chal

    %{amount: amount, milestone_distance: milestone_distance} = params

    new_pledged = Decimal.add(total_pledged, amount)

    Challenges.update_ngo_chal(ngo_chal, %{total_pledged: new_pledged})

    %Donation{user_id: user_id, ngo_chal_id: ngo_chal_id, ngo_id: ngo_id, milestone_distance: milestone_distance}
    |> Donation.changeset(params)
    |> Repo.insert()
  end

  # create donations with kickstarter
  def create_donations(rel_params, milestones, kickstarter, currency, str_src, cus_id) do
    multi =
      Multi.new
      |> Multi.run(:kickstarter, fn %{} ->
          create_donation(rel_params, %{amount: Decimal.new(kickstarter), milestone: 0, currency: currency, milestone_distance: 0, str_src: str_src, str_cus_id: cus_id, status: "charged"})
        end)
      |> Multi.run(:milestones, fn %{} ->
          insert_milestones(rel_params, milestones, currency, str_src, cus_id)
          {:ok, %{"message" => "milestones inserted"}}
        end)

      case Repo.transaction(multi) do
        {:ok, message} ->
          {:ok, message}
        {:error, _} ->
          {:error, "Error"}
      end
  end

  # for no kickstarter
  def create_donations(rel_params, milestones, currency, str_src, cus_id) do
    case insert_milestones(rel_params, milestones, currency, str_src, cus_id) do
      {:ok, result} ->
        {:ok, result}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp insert_milestones(rel_params, milestones, currency, str_src, cus_id) do
    %{ngo_chal_id: ngo_chal_id} = rel_params

    ngo_chal = Challenges.get_ngo_chal!(ngo_chal_id)

    Enum.each(milestones, fn {milestone, amount} ->
      %{distance_target: distance_target} = ngo_chal

      targets = case distance_target do
                  50 -> %{ 1 => 15, 2 => 25, 3 => 50}
                  75 -> %{ 1 => 25, 2 => 45, 3 => 75}
                  150 -> %{ 1 => 50, 2 => 100, 3 => 150}
                  250 -> %{ 1 => 75, 2 => 150, 3 => 250}
                end

      %{^milestone => milestone_distance} = targets

      if amount != nil do
        create_donation(rel_params, %{amount: Decimal.new(amount), milestone: milestone, milestone_distance: milestone_distance, currency: currency, str_src: str_src, str_cus_id: cus_id, status: "pending"})
      end
    end)

    {:ok, "milestones created"}
  end

  def update_donation(%Donation{} = donation, attrs) do
    donation
    |> Donation.changeset(attrs)
    |> Repo.update()
  end

  def delete_donation(%Donation{} = donation) do
    Repo.delete(donation)
  end

  def change_donation(%Donation{} = donation) do
    Donation.changeset(donation, %{})
  end

  def list_tips do
    Repo.all(Tip)
  end

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

  def delete_tip(%Tip{} = tip) do
    Repo.delete(tip)
  end

  def change_tip(%Tip{} = tip) do
    Tip.changeset(tip, %{})
  end
end
