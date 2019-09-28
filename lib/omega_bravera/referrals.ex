defmodule OmegaBravera.Referrals do
  @moduledoc """
  The Referrals context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Referrals.Referral

  @doc """
  Returns the list of referrals.

  ## Examples

      iex> list_referrals()
      [%Referral{}, ...]

  """
  def list_referrals do
    Repo.all(Referral)
  end

  @doc """
  Gets a single referral.

  Raises `Ecto.NoResultsError` if the Referral does not exist.

  ## Examples

      iex> get_referral!(123)
      %Referral{}

      iex> get_referral!(456)
      ** (Ecto.NoResultsError)

  """
  def get_referral!(id), do: Repo.get!(Referral, id)

  def get_or_create_referral(user_id) do
    case Repo.get_by(Referral, user_id: user_id) do
      nil ->
        create_referral(%{"user_id" => user_id})

      referral ->
        {:ok, referral}
    end
  end

  def get_referral_by_token(nil), do: nil

  def get_referral_by_token(token) do
    from(r in Referral, where: r.token == ^token) |> Repo.one()
  end

  @doc """
  Creates a referral.

  ## Examples

      iex> create_referral(%{field: value})
      {:ok, %Referral{}}

      iex> create_referral(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_referral(attrs \\ %{}) do
    %Referral{}
    |> Referral.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a referral.

  ## Examples

      iex> update_referral(referral, %{field: new_value})
      {:ok, %Referral{}}

      iex> update_referral(referral, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_referral(%Referral{} = referral, attrs) do
    referral
    |> Referral.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Referral.

  ## Examples

      iex> delete_referral(referral)
      {:ok, %Referral{}}

      iex> delete_referral(referral)
      {:error, %Ecto.Changeset{}}

  """
  def delete_referral(%Referral{} = referral) do
    Repo.delete(referral)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking referral changes.

  ## Examples

      iex> change_referral(referral)
      %Ecto.Changeset{source: %Referral{}}

  """
  def change_referral(%Referral{} = referral) do
    Referral.changeset(referral, %{})
  end
end
