defmodule OmegaBravera.Money do
  @moduledoc """
  The Money context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Money.Donation

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
end
