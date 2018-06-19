defmodule OmegaBravera.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Ecto.Multi
  alias OmegaBravera.Repo

  alias OmegaBravera.Accounts.{User, Credential}
  alias OmegaBravera.Trackers
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Challenges.NGOChal

  def get_strava_challengers(athlete_id) do
    query = from s in Strava,
      where: s.athlete_id == ^athlete_id,
      join: nc in NGOChal, where: s.user_id == nc.user_id and nc.status == "Active",
      select: {
        nc.id,
        s.token
      }

    query
    |> Repo.all()
  end

  # TODO Optimize the preload below

  def get_user_strava!(user_id) do
    query = from u in User,
      where: u.id == ^user_id,
      join: s in Strava, where: s.user_id == ^user_id

    query |> Repo.one()
  end

  def get_user_with_everything!(user_id) do
    user = User

    user
    |> where([user], user.id == ^user_id)
    |> join(:left, [user], ngo_chals in assoc(user, :ngo_chals))
    |> join(:left, [user], ngo_chals in assoc(user, :ngo_chals))
    |> join(:left, [user, ngo_chals], donations in assoc(ngo_chals, :donations))
    |> preload([user, ngo_chals, donations], [ngo_chals: {ngo_chals, donations: donations}])
    |> Repo.one
    |> Repo.preload(:strava)
  end

  @doc """
  Inserts or updates strava user with create_strava_user func below
  """

  def insert_or_update_strava_user(changeset) do
    %{email: email, firstname: firstname, lastname: lastname, token: token, athlete_id: athlete_id} = changeset

    user_changeset = %{"email" => email, "firstname" => firstname, "lastname" => lastname}

    strava_changeset = %{"token" => token, "email" => email, "firstname" => firstname, "lastname" => lastname, "athlete_id" => athlete_id}

    case Repo.get_by(User, email: email) do
      nil ->
         create_strava_user(user_changeset, strava_changeset)
      user ->
        %{id: user_id} = user
        case Repo.get_by(Strava, user_id: user_id) do
          nil ->
            Trackers.create_strava(user_id, strava_changeset)
          strava ->
            %{token: strava_token} = strava
            unless strava_token == token do
              Trackers.update_strava(strava, strava_changeset)
            end
            {:ok, user}
        end
    end
  end

  def create_strava_user(user_changeset, strava_changeset) do

    Multi.new
    |> Multi.run(:user, fn %{} -> create_user(user_changeset) end)
    |> Multi.run(:strava, fn %{user: user} ->
       Trackers.create_strava(user.id, strava_changeset)
       end)
    |> Repo.transaction()
  end

  @doc """
    Creates User with a credential
  """

  def create_credentialed_user(%{"user" => %{"email" => email, "password" => password, "password_confirmation" => password_confirmation}}) do

    Multi.new
    |> Multi.run(:user, fn %{} -> create_user(%{"email" => email}) end)
    |> Multi.run(:credential, fn %{user: %{id: user_id}} ->
       create_credential(user_id, %{"password" => password, "password_confirmation" => password_confirmation})
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

        query = from c in Credential,
          where: c.user_id == ^user_id

        query |> Repo.one
    end
  end

  @doc """
    Looks for credential based on reset token
  """

  def get_credential_by_token(token) do
    query = from c in Credential,
      where: c.reset_token == ^token

    query |> Repo.one
  end

  @doc """
    Inserts or returns an email user (if email is not already registered, insert it)
  """

  def insert_or_return_email_user(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        create_user(email)
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
    query = from c in Credential,
      where: c.user_id == ^user.id

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
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
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

end
