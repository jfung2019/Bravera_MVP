defmodule OmegaBravera.Fundraisers do
  @moduledoc """
  The Fundraisers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Fundraisers.NGO

  # Get a user's causes by user_id

  def get_ngos_by_user(user_id) do
    query =
      from(n in NGO,
        where: n.user_id == ^user_id
      )

    Repo.all(query)
  end

  def get_donations_for_ngo(slug) do
    from(
      n in NGO,
      where: n.slug == ^slug,
      left_join: ngo_user in assoc(n, :user),
      left_join: donations in assoc(n, :donations),
      on: donations.status == "charged",
      left_join: user in assoc(donations, :user),
      left_join: ngo_chal in assoc(donations, :ngo_chal),
      preload: [user: ngo_user, donations: {donations, user: user, ngo_chal: ngo_chal}]
    )
    |> Repo.one()
  end

  def get_monthly_donations_for_ngo(slug, start_date, end_date) do
    from(
      n in NGO,
      where: n.slug == ^slug,
      left_join: ngo_user in assoc(n, :user),
      left_join: donations in assoc(n, :donations),
      on: donations.status == "charged" and donations.charged_at >= ^start_date and donations.charged_at <= ^end_date,
      left_join: user in assoc(donations, :user),
      left_join: ngo_chal in assoc(donations, :ngo_chal),
      select: [
        ngo_chal.slug,
        donations.charge_id,
        fragment("to_char(?, 'YYYY-MM-DD HH:MI')", donations.charged_at),
        fragment("concat(?, ' - ', ?)", ngo_user.firstname, ngo_user.lastname),
        fragment("concat(?, ' - ', ?)", user.firstname, user.lastname),
        user.email,
        donations.milestone,
        ngo_chal.default_currency,
        fragment("ROUND((? * ?), 1)", donations.amount, donations.exchange_rate),
        fragment("ROUND(((? * ?) * 0.034) + 2.35, 1)", donations.amount, donations.exchange_rate),
        fragment("ROUND((? * ?) * 0.06, 1)", donations.amount, donations.exchange_rate),
        fragment("ROUND(
          ((? * ?) - (((? * ?) * 0.034) + 2.35)) - ((? * ?) * 0.06), 1)",
          donations.exchange_rate,
          donations.amount,
          donations.exchange_rate,
          donations.amount,
          donations.amount,
          donations.exchange_rate
        )
      ]
    ) |> Repo.all()
  end

  @doc """
  Returns the list of ngos.

  ## Examples

      iex> list_ngos()
      [%NGO{}, ...]

  """
  def list_ngos do
    Repo.all(NGO)
  end

  def list_ngos_preload() do
    query =
      from(
        n in NGO,
        join: user in assoc(n, :user),
        join: strava in assoc(user, :strava),
        preload: [user: {user, strava: strava}]
      )

    query |> Repo.all()
  end

  @doc """
  Gets a single ngo.

  Raises `Ecto.NoResultsError` if the Ngo does not exist.

  ## Examples

      iex> get_ngo!(123)
      %NGO{}

      iex> get_ngo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ngo!(id), do: Repo.get!(NGO, id)

  def get_ngo_by_slug(slug) do
    query =
      from(n in NGO,
        where: n.slug == ^slug
      )

    Repo.one(query)
  end

  def get_ngo_by_slug(slug, :preload) do
    query =
      from(n in NGO,
        where: n.slug == ^slug
      )

    Repo.one(query) |> Repo.preload(:ngo_chals)
  end

  @doc """
  Creates a ngo.

  ## Examples

      iex> create_ngo(%{field: value})
      {:ok, %NGO{}}

      iex> create_ngo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ngo(attrs \\ %{}) do
    %NGO{}
    |> NGO.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ngo.

  ## Examples

      iex> update_ngo(ngo, %{field: new_value})
      {:ok, %NGO{}}

      iex> update_ngo(ngo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ngo(%NGO{} = ngo, attrs) do
    ngo
    |> NGO.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a NGO.

  ## Examples

      iex> delete_ngo(ngo)
      {:ok, %NGO{}}

      iex> delete_ngo(ngo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ngo(%NGO{} = ngo) do
    Repo.delete(ngo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ngo changes.

  ## Examples

      iex> change_ngo(ngo)
      %Ecto.Changeset{source: %NGO{}}

  """
  def change_ngo(%NGO{} = ngo) do
    NGO.changeset(ngo, %{})
  end

  def available_currencies, do: NGO.currency_options()

  def available_activities, do: NGO.activity_options()

  def available_distances, do: NGO.distance_options()

  def available_durations, do: NGO.duration_options()
end
