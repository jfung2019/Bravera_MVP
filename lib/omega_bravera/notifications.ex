defmodule OmegaBravera.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo
  alias Ecto.Multi

  alias OmegaBravera.Notifications.{EmailCategory, UserEmailCategories}

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
  list all EmailCategory and check if user gave permission or not
  """
  @spec list_email_categories_permission(integer()) :: [EmailCategory.t()]
  def list_email_categories_permission(user_id) do
    from(c in EmailCategory,
      left_join: u in UserEmailCategories,
      on: c.id == u.category_id and u.user_id == ^user_id,
      order_by: c.title,
      select: %{c | permitted: c.title == "Platform Notifications" or not is_nil(u.id)}
    )
    |> Repo.all()
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

  alias OmegaBravera.Notifications.SendgridEmail

  @doc """
  Returns the list of sendgrid_emails.

  ## Examples

      iex> list_sendgrid_emails()
      [%SendgridEmail{}, ...]

  """
  def list_sendgrid_emails do
    Repo.all(SendgridEmail)
  end

  def list_sendgrid_emails_query() do
    from(e in SendgridEmail, preload: [:category])
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

  def get_sendgrid_email_by_sendgrid_id(sendgrid_id) do
    from(
      sendgrid_email in SendgridEmail,
      where: sendgrid_email.sendgrid_id == ^sendgrid_id,
      preload: [:category]
    )
    |> Repo.one()
  end

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
  get UserEmailCategories from user_id and category_id
  """
  @spec get_user_email_category(integer(), integer()) :: UserEmailCategories.t() | nil
  def get_user_email_category(user_id, category_id) do
    from(u in UserEmailCategories, where: u.user_id == ^user_id and u.category_id == ^category_id)
    |> Repo.one()
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

  @doc """
  Checks if a user is in an email category so they can receive the email.
  if user_subscribed_categories is empty, it means that user is subscribed in all email_categories.
  """
  @spec user_subscribed_in_category?(list, %EmailCategory{}) :: bool
  def user_subscribed_in_category?(_user_subscribed_categories, %{title: "Platform Notifications"}),
      do: true

  def user_subscribed_in_category?([], _email_category), do: true

  def user_subscribed_in_category?(user_subscribed_categories, %{id: email_category_id}) do
    # User actually choose specific categories of emails.
    user_subscribed_categories
    |> Enum.map(& &1.category_id)
    |> Enum.member?(email_category_id)
  end

  alias OmegaBravera.Notifications.Device

  @doc """
  Returns the list of notification_devices.

  ## Examples

      iex> list_notification_devices()
      [%Device{}, ...]

  """
  def list_notification_devices do
    Repo.all(Device)
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device!(123)
      %Device{}

      iex> get_device!(456)
      ** (Ecto.NoResultsError)

  """
  def get_device!(id), do: Repo.get!(Device, id)

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a device.

  ## Examples

      iex> update_device(device, %{field: new_value})
      {:ok, %Device{}}

      iex> update_device(device, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking device changes.

  ## Examples

      iex> change_device(device)
      %Ecto.Changeset{source: %Device{}}

  """
  def change_device(%Device{} = device) do
    Device.changeset(device, %{})
  end

  @doc """
  Gets tokens of users whose last activity is X days ago.
  """
  @spec list_notification_devices_with_last_activity_from(integer()) :: list(String.t())
  def list_notification_devices_with_last_activity_from(days_ago) do
    date = Timex.now() |> Timex.shift(days: days_ago) |> Timex.to_date()

    from(nd in Device,
      left_join: u in assoc(nd, :user),
      on: u.push_notifications == true,
      left_join: a in assoc(u, :activities),
      group_by: nd.token,
      having: fragment("MAX(?)::DATE = ?", a.start_date, ^date),
      select: nd.token
    )
    |> Repo.all()
  end

  @doc """
  Get tokens of users with the days between the date of last activity and now dividable by 7d
  """
  @spec list_notification_devices_with_last_activity_every_7_days :: [Device.t()]
  def list_notification_devices_with_last_activity_every_7_days do
    from(nd in Device,
      left_join: u in assoc(nd, :user),
      on: u.push_notifications == true,
      left_join: a in assoc(u, :activities),
      where: not is_nil(a.device_id) and is_nil(a.strava_id),
      group_by: [nd.id, nd.token],
      having: fragment("(MAX(?)::date - now()::date) % 7 = 0", a.start_date)
    )
    |> Repo.all()
  end

  @doc """
  Gets push tokens of users who have an offer that will expire within X days.
  """
  @spec list_notification_devices_with_expiring_offer_redeem(integer()) :: [Device.t()]
  def list_notification_devices_with_expiring_offer_redeem(shift_days) do
    now = Timex.now()
    future = now |> Timex.shift(days: shift_days)

    from(nd in Device,
      left_join: u in assoc(nd, :user),
      on: u.push_notifications == true,
      left_join: r in assoc(u, :offer_redeems),
      on:
        r.status == "pending" and not is_nil(r.expired_at) and
          fragment("? BETWEEN ? AND ?", r.expired_at, ^now, ^future),
      group_by: [nd.id, nd.token],
      having: count(r.id) > 0
    )
    |> Repo.all()
  end

  @doc """
  List notification_devices of users who belong to a group with new member joined in the past 3 days
  """
  @spec list_notification_devices_with_new_group_member :: [Device.t()]
  def list_notification_devices_with_new_group_member do
    from(pm in OmegaBravera.Groups.Member,
      where: fragment("? BETWEEN now() - interval '3 days' AND now()", pm.inserted_at),
      distinct: [pm.partner_id],
      select: pm.partner_id
    )
    |> distinct_members_in_groups()
    |> list_notification_devices_of_users()
    |> Repo.all()
  end

  @doc """
  List notification_devices of users who have new messages in the past 2 hours
  """
  @spec list_notification_devices_with_new_message(String.t()) :: [Device.t()]
  def list_notification_devices_with_new_message(message_id) do
    from(pm in OmegaBravera.Groups.Member,
      left_join: p in assoc(pm, :partner),
      left_join: cm in assoc(p, :chat_messages),
      where: cm.id == ^message_id and is_nil(pm.mute_notification),
      select: pm.user_id
    )
    |> list_notification_devices_of_users()
    |> Repo.all()
  end

  # Query for getting distinct members from a group_id list
  @spec distinct_members_in_groups(Ecto.Query.t()) :: Ecto.Query.t()
  defp distinct_members_in_groups(query) do
    from(pm in OmegaBravera.Groups.Member,
      where: pm.partner_id in subquery(query),
      distinct: [pm.user_id],
      select: pm.user_id
    )
  end

  # Query for getting distinct user device from a user_id list
  @spec list_notification_devices_of_users(Ecto.Query.t()) :: Ecto.Query.t()
  defp list_notification_devices_of_users(query) do
    from(nd in Device,
      left_join: pm in OmegaBravera.Groups.Member,
      on: nd.user_id == pm.user_id,
      where: nd.user_id in subquery(query),
      distinct: [nd.user_id, nd.token]
    )
  end

  @doc """
  List notification_devices of the given user
  """
  @spec list_notification_devices_by_user_id(integer()) :: [Device.t()]
  def list_notification_devices_by_user_id(user_id) do
    from(nd in Device,
      left_join: u in assoc(nd, :user),
      on: u.push_notifications == true,
      where: nd.user_id == ^user_id,
      group_by: [nd.id, nd.token]
    )
    |> Repo.all()
  end
end
