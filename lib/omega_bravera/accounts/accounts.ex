defmodule OmegaBravera.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Ecto.Multi

  alias OmegaBravera.{
    Repo,
    Accounts,
    Accounts.User,
    Accounts.Credential,
    Money.Donation,
    Trackers,
    Trackers.Strava,
    Challenges.NGOChal,
    Money.Donation
  }

  def get_strava_challengers(athlete_id) do
    query =
      from(s in Strava,
        where: s.athlete_id == ^athlete_id,
        join: nc in NGOChal,
        where: s.user_id == nc.user_id and nc.status == "active",
        select: {
          nc.id,
          s.token
        }
      )

    Repo.all(query)
  end

  defp donors_for_challenge_query(challenge) do
    from(user in User,
      join: donation in Donation,
      on: donation.user_id == user.id,
      where: donation.ngo_chal_id == ^challenge.id,
      distinct: donation.user_id,
      order_by: user.id
    )
  end

  def donors_for_challenge(%NGOChal{} = challenge) do
    challenge
    |> donors_for_challenge_query()
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def latest_donors(%NGOChal{} = challenge, limit \\ nil) do
    query =
      challenge
      |> donors_for_challenge_query()
      |> order_by(desc: :inserted_at)
      |> group_by([user, donation], [user.id, donation.user_id, donation.currency])
      |> select([user, donation], {user, sum(donation.amount), donation.currency})

    query =
      if is_number(limit) and limit > 0 do
        limit(query, ^limit)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.map(fn {user, amount, currency} ->
      %{"user" => user, "pledged" => amount, "currency" => currency}
    end)
  end

  defp donors_for_ngo_query(ngo) do
    from(user in User,
      join: donation in Donation,
      on: donation.user_id == user.id,
      where: donation.ngo_chal_id == ^ngo.id,
      distinct: donation.user_id,
      order_by: user.id
    )
  end

  # TODO Optimize the preload below
  def get_user_strava(user_id) do
    query = from(s in Strava, where: s.user_id == ^user_id)
    Repo.one(query)
  end

  # TODO I think I was being cute with this, do we use?
  #
  # def get_user_strava!(user_id) do
  #   query = from u in User,
  #     where: u.id == ^user_id,
  #     join: s in Strava, where: s.user_id == ^user_id
  #
  #   query |> Repo.one()
  # end

  def get_user_with_everything!(user_id) do
    user = User

    user
    |> where([user], user.id == ^user_id)
    |> join(:left, [user], ngo_chals in assoc(user, :ngo_chals))
    |> join(:left, [user], ngo_chals in assoc(user, :ngo_chals))
    |> join(:left, [user, ngo_chals], donations in assoc(ngo_chals, :donations))
    |> preload([user, ngo_chals, donations], ngo_chals: {ngo_chals, donations: donations})
    |> Repo.one()
    |> Repo.preload(:strava)
  end

  @doc """
  Inserts or updates strava user with create_strava_user func below
  """

  def insert_or_update_strava_user(changeset) do
    case Repo.get_by(User, email: changeset[:email]) do
      nil ->
        Accounts.Strava.create_user_with_tracker_and_email(changeset)

      user ->
        updated_user =
          case Accounts.update_user(user, changeset) do
            {:ok, u} -> u
            {:error, _} -> user
          end

        Trackers.create_or_update_tracker(updated_user, changeset)
        {:ok, updated_user}
    end
  end

  @doc """
    Creates User with a credential
  """

  def create_credentialed_user(%{
        "user" => %{
          "email" => email,
          "password" => password,
          "password_confirmation" => password_confirmation
        }
      }) do
    Multi.new()
    |> Multi.run(:user, fn %{} -> create_user(%{"email" => email}) end)
    |> Multi.run(:credential, fn %{user: %{id: user_id}} ->
      create_credential(user_id, %{
        "password" => password,
        "password_confirmation" => password_confirmation
      })
    end)
    |> Repo.transaction()
  end

  @doc """
    Looks for credential based on user email
  """

  def get_user_credential(email) do
    #  there used to be credential = here, don't think it is used
    case email do
      nil ->
        nil

      email ->
        %{id: user_id} = User |> Repo.get_by(email: email)

        query =
          from(c in Credential,
            where: c.user_id == ^user_id
          )

        query |> Repo.one()
    end
  end

  @doc """
    Looks for credential based on reset token
  """

  def get_credential_by_token(token) do
    query =
      from(c in Credential,
        where: c.reset_token == ^token
      )

    query |> Repo.one()
  end

  @doc """
    Inserts or returns an email user (if email is not already registered, insert it)
  """
  def insert_or_return_email_user(%{"email" => email, "first_name" => first, "last_name" => last}) do
    case Repo.get_by(User, email: email) do
      nil ->
        case create_user(%{"email" => email, "firstname" => first, "lastname" => last}) do
          {:ok, user} -> user
          {:error, _reason} -> nil
        end

      user ->
        user
    end
  end

  @doc """
  Functions for password-based user credentials
  """

  def email_password_auth(email, password) when is_binary(email) and is_binary(password) do
    with {:ok, user} <- get_by_email(email),
         do: verify_password(password, user)
  end

  defp get_by_email(email) when is_binary(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        dummy_checkpw()
        {:error, "Login error."}

      user ->
        {:ok, user}
    end
  end

  defp verify_password(password, user) when is_binary(password) do
    query =
      from(c in Credential,
        where: c.user_id == ^user.id
      )

    credential = Repo.one(query)

    if checkpw(password, credential.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    case attrs do
    %{password: password} when password != nil ->
      %User{}
      |> User.changeset_with_password(attrs)
      |> Repo.insert()
    _ ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc """
  Gets a single credential.

  Raises `Ecto.NoResultsError` if the Credential does not exist.

  ## Examples

      iex> get_credential!(123)
      %Credential{}

      iex> get_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credential!(id), do: Repo.get!(Credential, id)

  @doc """
  Creates a credential.

  ## Examples

      iex> create_credential(%{field: value})
      {:ok, %Credential{}}

      iex> create_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credential(user_id, attrs \\ %{}) do
    %Credential{user_id: user_id}
    |> Credential.changeset(attrs)
    |> Repo.insert()
  end

  # Check to see if email is taken by User
  # If not, create User and create Associated Credential (passwords)

  @doc """
  Updates a credential.

  ## Examples

      iex> update_credential(credential, %{field: new_value})
      {:ok, %Credential{}}

      iex> update_credential(credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_credential(%Credential{} = credential, attrs) do
    credential
    |> Credential.changeset(attrs)
    |> Repo.update()
  end

  def update_credential_token(%Credential{} = credential, attrs) do
    credential
    |> Credential.token_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Credential.

  ## Examples

      iex> delete_credential(credential)
      {:ok, %Credential{}}

      iex> delete_credential(credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_credential(%Credential{} = credential) do
    Repo.delete(credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credential changes.

  ## Examples

      iex> change_credential(credential)
      %Ecto.Changeset{source: %Credential{}}

  """
  def change_credential(%Credential{} = credential) do
    Credential.changeset(credential, %{})
  end

  alias OmegaBravera.Accounts.Setting

  @doc """
  Returns the list of settings.

  ## Examples

      iex> list_settings()
      [%Setting{}, ...]

  """
  def list_settings do
    Repo.all(Setting)
  end

  @doc """
  Gets a single setting.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!(123)
      %Setting{}

      iex> get_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_setting!(id), do: Repo.get!(Setting, id)

  @doc """
  Creates a setting.

  ## Examples

      iex> create_setting(%{field: value})
      {:ok, %Setting{}}

      iex> create_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_setting(attrs \\ %{}) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting(setting, %{field: new_value})
      {:ok, %Setting{}}

      iex> update_setting(setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Setting.

  ## Examples

      iex> delete_setting(setting)
      {:ok, %Setting{}}

      iex> delete_setting(setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_setting(%Setting{} = setting) do
    Repo.delete(setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{source: %Setting{}}

  """
  def change_setting(%Setting{} = setting) do
    Setting.changeset(setting, %{})
  end

  alias OmegaBravera.Accounts.AdminUser

  @doc """
  Returns the list of admin_users.

  ## Examples

      iex> list_admin_users()
      [%AdminUser{}, ...]

  """
  def list_admin_users do
    Repo.all(AdminUser)
  end

  @doc """
  Gets a single admin_user.

  Raises `Ecto.NoResultsError` if the Admin user does not exist.

  ## Examples

      iex> get_admin_user!(123)
      %AdminUser{}

      iex> get_admin_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin_user!(id), do: Repo.get!(AdminUser, id)

  @doc """
  Creates a admin_user.

  ## Examples

      iex> create_admin_user(%{field: value})
      {:ok, %AdminUser{}}

      iex> create_admin_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_admin_user(attrs \\ %{}) do
    %AdminUser{}
    |> AdminUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a admin_user.

  ## Examples

      iex> update_admin_user(admin_user, %{field: new_value})
      {:ok, %AdminUser{}}

      iex> update_admin_user(admin_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_user(%AdminUser{} = admin_user, attrs) do
    admin_user
    |> AdminUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a AdminUser.

  ## Examples

      iex> delete_admin_user(admin_user)
      {:ok, %AdminUser{}}

      iex> delete_admin_user(admin_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_admin_user(%AdminUser{} = admin_user) do
    Repo.delete(admin_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin_user changes.

  ## Examples

      iex> change_admin_user(admin_user)
      %Ecto.Changeset{source: %AdminUser{}}

  """
  def change_admin_user(%AdminUser{} = admin_user) do
    AdminUser.changeset(admin_user, %{})
  end

  @doc """
  Returns a user in an :ok tuple if user is found by email and correct password.
  Otherwise an error tuple is returned.
  """
  def authenticate_admin_user_by_email_and_pass(email, given_pass) do
    email = String.downcase(email)

    user =
      from(u in AdminUser, where: fragment("lower(?) = ?", u.email, ^email))
      |> Repo.one()

    cond do
      user && Comeonin.Bcrypt.checkpw(given_pass, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        Comeonin.Bcrypt.dummy_checkpw()
        {:error, :not_found}
    end
  end
end
