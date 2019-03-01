defmodule OmegaBravera.Emails do
  @moduledoc """
  The Emails context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo
  alias Ecto.Multi

  alias OmegaBravera.Emails.EmailCategory

  @doc """
  Returns the list of email_categories.

  ## Examples

      iex> list_email_categories()
      [%EmailCategory{}, ...]

  """
  def list_email_categories do
    Repo.all(EmailCategory)
  end

  @doc """
  Gets a single email_category.

  Raises `Ecto.NoResultsError` if the Email category does not exist.

  ## Examples

      iex> get_email_category!(123)
      %EmailCategory{}

      iex> get_email_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_email_category!(id), do: Repo.get!(EmailCategory, id)

  def get_email_category_by_title(title) do
    from(
      email_category in EmailCategory,
      where: email_category.title == ^title
    )
    |> Repo.one()
  end

  @doc """
  Creates a email_category.

  ## Examples

      iex> create_email_category(%{field: value})
      {:ok, %EmailCategory{}}

      iex> create_email_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_email_category(attrs \\ %{}) do
    %EmailCategory{}
    |> EmailCategory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a email_category.

  ## Examples

      iex> update_email_category(email_category, %{field: new_value})
      {:ok, %EmailCategory{}}

      iex> update_email_category(email_category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_email_category(%EmailCategory{} = email_category, attrs) do
    email_category
    |> EmailCategory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a EmailCategory.

  ## Examples

      iex> delete_email_category(email_category)
      {:ok, %EmailCategory{}}

      iex> delete_email_category(email_category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_email_category(%EmailCategory{} = email_category) do
    Repo.delete(email_category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email_category changes.

  ## Examples

      iex> change_email_category(email_category)
      %Ecto.Changeset{source: %EmailCategory{}}

  """
  def change_email_category(%EmailCategory{} = email_category) do
    EmailCategory.changeset(email_category, %{})
  end

  alias OmegaBravera.Emails.SendgridEmail

  @doc """
  Returns the list of sendgrid_emails.

  ## Examples

      iex> list_sendgrid_emails()
      [%SendgridEmail{}, ...]

  """
  def list_sendgrid_emails do
    Repo.all(SendgridEmail)
  end

  @doc """
  Gets a single sendgrid_email.

  Raises `Ecto.NoResultsError` if the Sendgrid email does not exist.

  ## Examples

      iex> get_sendgrid_email!(123)
      %SendgridEmail{}

      iex> get_sendgrid_email!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sendgrid_email!(id), do: Repo.get!(SendgridEmail, id)

  @doc """
  Creates a sendgrid_email.

  ## Examples

      iex> create_sendgrid_email(%{field: value})
      {:ok, %SendgridEmail{}}

      iex> create_sendgrid_email(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sendgrid_email(attrs \\ %{}) do
    %SendgridEmail{}
    |> SendgridEmail.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sendgrid_email.

  ## Examples

      iex> update_sendgrid_email(sendgrid_email, %{field: new_value})
      {:ok, %SendgridEmail{}}

      iex> update_sendgrid_email(sendgrid_email, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sendgrid_email(%SendgridEmail{} = sendgrid_email, attrs) do
    sendgrid_email
    |> SendgridEmail.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a SendgridEmail.

  ## Examples

      iex> delete_sendgrid_email(sendgrid_email)
      {:ok, %SendgridEmail{}}

      iex> delete_sendgrid_email(sendgrid_email)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sendgrid_email(%SendgridEmail{} = sendgrid_email) do
    Repo.delete(sendgrid_email)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sendgrid_email changes.

  ## Examples

      iex> change_sendgrid_email(sendgrid_email)
      %Ecto.Changeset{source: %SendgridEmail{}}

  """
  def change_sendgrid_email(%SendgridEmail{} = sendgrid_email) do
    SendgridEmail.changeset(sendgrid_email, %{})
  end

  alias OmegaBravera.Emails.UserEmailCategories

  @doc """
  Returns the list of user_email_categories.

  ## Examples

      iex> list_user_email_categories()
      [%UserEmailCategories{}, ...]

  """
  def list_user_email_categories do
    Repo.all(UserEmailCategories)
  end

  @doc """
  Gets a single user_email_categories.

  Raises `Ecto.NoResultsError` if the User email categories does not exist.

  ## Examples

      iex> get_user_email_categories!(123)
      %UserEmailCategories{}

      iex> get_user_email_categories!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_email_categories!(id), do: Repo.get!(UserEmailCategories, id)

  def get_user_subscribed_email_categories(user_id, preloads \\ [:category]) do
    from(
      user_categories in UserEmailCategories,
      where: user_categories.user_id == ^user_id,
      preload: ^preloads
    )
    |> Repo.all()
  end

  @doc """
  Creates a user_email_categories.

  ## Examples

      iex> create_user_email_categories(%{field: value})
      {:ok, %UserEmailCategories{}}

      iex> create_user_email_categories(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_email_categories(attrs \\ %{}) do
    %UserEmailCategories{}
    |> UserEmailCategories.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_email_categories.

  ## Examples

      iex> update_user_email_categories(user_email_categories, %{field: new_value})
      {:ok, %UserEmailCategories{}}

      iex> update_user_email_categories(user_email_categories, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_email_categories(%UserEmailCategories{} = user_email_categories, attrs) do
    user_email_categories
    |> UserEmailCategories.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a UserEmailCategories.

  ## Examples

      iex> delete_user_email_categories(user_email_categories)
      {:ok, %UserEmailCategories{}}

      iex> delete_user_email_categories(user_email_categories)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_email_categories(%UserEmailCategories{} = user_email_categories) do
    Repo.delete(user_email_categories)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_email_categories changes.

  ## Examples

      iex> change_user_email_categories(user_email_categories)
      %Ecto.Changeset{source: %UserEmailCategories{}}

  """
  def change_user_email_categories(%UserEmailCategories{} = user_email_categories) do
    UserEmailCategories.changeset(user_email_categories, %{})
  end

  @doc """
    Deletes all existing rows of user email subscriptions to categories
    and creates new ones based on their choosing from the UI.

    By default, a user is subscribed to all emails.
    By default, a user has no rows in user_email_categories
  """
  def delete_and_update_user_email_categories(new_subscribed_categories, user) do
    delete_existing =
      from(
        uec in UserEmailCategories,
        where: uec.user_id == ^user.id
      )

    new_subscribed_categories =
      Enum.map(new_subscribed_categories, fn new_subscribed_category ->
        %{
          category_id: new_subscribed_category,
          user_id: user.id,
          inserted_at: DateTime.truncate(Timex.now(), :second),
          updated_at: DateTime.truncate(Timex.now(), :second)
        }
      end)

    Multi.new()
    |> Multi.delete_all(:delete_all, delete_existing)
    |> Multi.insert_all(:insert_all, UserEmailCategories, new_subscribed_categories)
    |> Repo.transaction()
  end
end
