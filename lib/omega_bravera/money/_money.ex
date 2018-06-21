defmodule OmegaBravera.Money do
  @moduledoc """
  The Money context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo
  alias Ecto.Multi

  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Money.Tip

  # for charging from strava webhooks

  def get_donations_by_milestone(participant, milestone_limit) do
    query = from d in Donation,
      where: d.status == "pending" and d.milestone <= ^milestone_limit and d.participant_id == ^participant

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

    %Donation{user_id: user_id, ngo_chal_id: ngo_chal_id, ngo_id: ngo_id}
    |> Donation.changeset(params)
    |> Repo.insert()
  end

# create donations with kickstarter
  def create_donations(rel_params, milestones, kickstarter, currency, str_src) do
    multi =
      Multi.new
      |> Multi.run(:kickstarter, fn %{} ->
          create_donation(rel_params, %{amount: Decimal.new(kickstarter), milestone: 0, currency: currency, str_src: str_src, status: "charged"})
        end)
      |> Multi.run(:milestones, fn %{} ->
          insert_milestones(rel_params, milestones, currency, str_src)
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
  def create_donations(rel_params, milestones, currency, str_src) do
    case insert_milestones(rel_params, milestones, currency, str_src) do
      {:ok, result} ->
        {:ok, result}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp insert_milestones(rel_params, milestones, currency, str_src) do
    Enum.each(milestones, fn {milestone, amount} ->
      create_donation(rel_params, %{amount: Decimal.new(amount), milestone: milestone, currency: currency, str_src: str_src, status: "pending"})
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
