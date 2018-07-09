defmodule OmegaBravera.Money do
  @moduledoc """
  The Money context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo
  alias Ecto.Multi

  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Money.Tip
  alias OmegaBravera.Challenges

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

    result = Repo.all(query)
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

  @doc """
  Returns the list of donations.

  ## Examples

      iex> list_donations()
      [%Donation{}, ...]

  """
  def list_donations do
    Repo.all(Donation)
  end

  @doc """
  Gets a single donation.

  Raises `Ecto.NoResultsError` if the Donation does not exist.

  ## Examples

      iex> get_donation!(123)
      %Donation{}

      iex> get_donation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_donation!(id), do: Repo.get!(Donation, id)

  @doc """
  Creates a donation.

  ## Examples

      iex> create_donation(%{field: value})
      {:ok, %Donation{}}

      iex> create_donation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

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

      create_donation(rel_params, %{amount: Decimal.new(amount), milestone: milestone, milestone_distance: milestone_distance, currency: currency, str_src: str_src, str_cus_id: cus_id, status: "pending"})
    end)
    {:ok, "milestones created"}
  end

  @doc """
  Updates a donation.

  ## Examples

      iex> update_donation(donation, %{field: new_value})
      {:ok, %Donation{}}

      iex> update_donation(donation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_donation(%Donation{} = donation, attrs) do
    donation
    |> Donation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Donation.

  ## Examples

      iex> delete_donation(donation)
      {:ok, %Donation{}}

      iex> delete_donation(donation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_donation(%Donation{} = donation) do
    Repo.delete(donation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking donation changes.

  ## Examples

      iex> change_donation(donation)
      %Ecto.Changeset{source: %Donation{}}

  """
  def change_donation(%Donation{} = donation) do
    Donation.changeset(donation, %{})
  end


    @doc """
    Returns the list of tips.

    ## Examples

        iex> list_tips()
        [%Tip{}, ...]

    """
    def list_tips do
      Repo.all(Tip)
    end

    @doc """
    Gets a single tip.

    Raises `Ecto.NoResultsError` if the Tip does not exist.

    ## Examples

        iex> get_tip!(123)
        %Tip{}

        iex> get_tip!(456)
        ** (Ecto.NoResultsError)

    """
    def get_tip!(id), do: Repo.get!(Tip, id)

    @doc """
    Creates a tip.

    ## Examples

        iex> create_tip(%{field: value})
        {:ok, %Tip{}}

        iex> create_tip(%{field: bad_value})
        {:error, %Ecto.Changeset{}}

    """
    def create_tip(attrs \\ %{}) do
      %Tip{}
      |> Tip.changeset(attrs)
      |> Repo.insert()
    end

    @doc """
    Updates a tip.

    ## Examples

        iex> update_tip(tip, %{field: new_value})
        {:ok, %Tip{}}

        iex> update_tip(tip, %{field: bad_value})
        {:error, %Ecto.Changeset{}}

    """
    def update_tip(%Tip{} = tip, attrs) do
      tip
      |> Tip.changeset(attrs)
      |> Repo.update()
    end

    @doc """
    Deletes a Tip.

    ## Examples

        iex> delete_tip(tip)
        {:ok, %Tip{}}

        iex> delete_tip(tip)
        {:error, %Ecto.Changeset{}}

    """
    def delete_tip(%Tip{} = tip) do
      Repo.delete(tip)
    end

    @doc """
    Returns an `%Ecto.Changeset{}` for tracking tip changes.

    ## Examples

        iex> change_tip(tip)
        %Ecto.Changeset{source: %Tip{}}

    """
    def change_tip(%Tip{} = tip) do
      Tip.changeset(tip, %{})
    end
end
