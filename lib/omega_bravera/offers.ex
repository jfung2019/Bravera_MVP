defmodule OmegaBravera.Offers do
  @moduledoc """
  The Offers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Offers.Offer

  @doc """
  Returns the list of offers.

  ## Examples

      iex> list_offers()
      [%Offer{}, ...]

  """
  def list_offers do
    Repo.all(Offer)
  end

  @doc """
  Gets a single offer.

  Raises `Ecto.NoResultsError` if the Offer does not exist.

  ## Examples

      iex> get_offer!(123)
      %Offer{}

      iex> get_offer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer!(id), do: Repo.get!(Offer, id)

  @doc """
  Creates a offer.

  ## Examples

      iex> create_offer(%{field: value})
      {:ok, %Offer{}}

      iex> create_offer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> switch_pre_registration_date_to_utc()
    |> switch_launch_date_to_utc()
    |> Repo.insert()
  end

  defp switch_pre_registration_date_to_utc(
         %Ecto.Changeset{
           valid?: true,
           changes: %{pre_registration_start_date: pre_registration_start_date}
         } = changeset
       ) do
    changeset
    |> Ecto.Changeset.change(%{
      pre_registration_start_date: pre_registration_start_date |> to_utc()
    })
  end

  defp switch_pre_registration_date_to_utc(%Ecto.Changeset{} = changeset), do: changeset

  defp switch_launch_date_to_utc(
         %Ecto.Changeset{valid?: true, changes: %{launch_date: launch_date}} = changeset
       ) do
    changeset
    |> Ecto.Changeset.change(%{
      launch_date: launch_date |> to_utc()
    })
  end

  defp switch_launch_date_to_utc(%Ecto.Changeset{} = changeset), do: changeset

  defp to_utc(%DateTime{} = datetime) do
    datetime
    |> Timex.to_datetime()
    |> DateTime.to_naive()
    |> Timex.to_datetime("Asia/Hong_Kong")
    |> Timex.to_datetime("Etc/UTC")
  end

  @doc """
  Updates a offer.

  ## Examples

      iex> update_offer(offer, %{field: new_value})
      {:ok, %Offer{}}

      iex> update_offer(offer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer(%Offer{} = offer, attrs) do
    offer
    |> Offer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Offer.

  ## Examples

      iex> delete_offer(offer)
      {:ok, %Offer{}}

      iex> delete_offer(offer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer(%Offer{} = offer) do
    Repo.delete(offer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer changes.

  ## Examples

      iex> change_offer(offer)
      %Ecto.Changeset{source: %Offer{}}

  """
  def change_offer(%Offer{} = offer) do
    Offer.changeset(offer, %{})
  end
end
