defmodule OmegaBravera.Stripe do
  @moduledoc """
  The Stripe context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Stripe.StrCustomer

  def get_user_str_customer(user_id) do
    query = from c in StrCustomer, where: c.user_id == ^user_id

    query |> Repo.one
  end


  @doc """
  Returns the list of str_customers.

  ## Examples

      iex> list_str_customers()
      [%StrCustomer{}, ...]

  """
  def list_str_customers do
    Repo.all(StrCustomer)
  end

  @doc """
  Gets a single str_customer.

  Raises `Ecto.NoResultsError` if the Str customer does not exist.

  ## Examples

      iex> get_str_customer!(123)
      %StrCustomer{}

      iex> get_str_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_str_customer!(id), do: Repo.get!(StrCustomer, id)

  @doc """
  Creates a str_customer.

  ## Examples

      iex> create_str_customer(user_id, %{field: value})
      {:ok, %StrCustomer{}}

      iex> create_str_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_str_customer(user_id, attrs \\ %{}) do
    %StrCustomer{user_id: user_id}
    |> StrCustomer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a str_customer.

  ## Examples

      iex> update_str_customer(str_customer, %{field: new_value})
      {:ok, %StrCustomer{}}

      iex> update_str_customer(str_customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_str_customer(%StrCustomer{} = str_customer, attrs) do
    str_customer
    |> StrCustomer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a StrCustomer.

  ## Examples

      iex> delete_str_customer(str_customer)
      {:ok, %StrCustomer{}}

      iex> delete_str_customer(str_customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_str_customer(%StrCustomer{} = str_customer) do
    Repo.delete(str_customer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking str_customer changes.

  ## Examples

      iex> change_str_customer(str_customer)
      %Ecto.Changeset{source: %StrCustomer{}}

  """
  def change_str_customer(%StrCustomer{} = str_customer) do
    StrCustomer.changeset(str_customer, %{})
  end
end
