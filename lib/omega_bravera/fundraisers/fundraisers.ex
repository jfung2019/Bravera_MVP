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
      on:
        donations.status == "charged" and donations.charged_at >= ^start_date and
          donations.charged_at <= ^end_date,
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
        fragment(
          "ROUND(
          ((? * ?) - (((? * ?) * 0.034) + 2.35)) - ((? * ?) * 0.06), 1)",
          donations.exchange_rate,
          donations.amount,
          donations.exchange_rate,
          donations.amount,
          donations.amount,
          donations.exchange_rate
        )
      ]
    )
    |> Repo.all()
  end

  def get_ngo_with_stats(slug, preloads \\ [:ngo_chals]) do
    ngo = get_ngo_by_slug(slug, preloads)

    total_pledged = Repo.one(
      from(
        donation in OmegaBravera.Money.Donation,
        where: donation.ngo_id == ^ngo.id,
        select: fragment("SUM( CASE WHEN km_distance IS NOT NULL THEN amount * km_distance ELSE amount END )")
      )
    )

    total_secured = Repo.aggregate(
      from(
        donation in OmegaBravera.Money.Donation,
        where: donation.ngo_id == ^ngo.id
      ),
      :sum,
      :charged_amount
    )

    calories_and_activities_query = from(
      activity in OmegaBravera.Challenges.Activity,
      join: challenge in assoc(activity, :challenge),
      where: challenge.ngo_id == ^ngo.id and activity.challenge_id == challenge.id
    )
    total_distance_covered = Repo.aggregate(calories_and_activities_query, :sum, :distance)
    total_calories = Repo.aggregate(calories_and_activities_query, :sum, :calories)

    %{
      ngo |
      total_pledged: total_pledged,
      total_secured: total_secured,
      num_of_challenges: Enum.count(ngo.ngo_chals),
      total_distance_covered: Decimal.round(total_distance_covered || Decimal.new(0)),
      total_calories: total_calories
    }
  end

  @doc """
  Returns the list of ngos.

  ## Examples

      iex> list_ngos()
      [%NGO{}, ...]

  """
  def list_ngos(hidden \\ false) do
    from(
      n in NGO,
      where: n.hidden == ^hidden
    )
    |> Repo.all()
  end

  def list_ngos_preload() do
    from(
      n in NGO,
      join: user in assoc(n, :user),
      join: strava in assoc(user, :strava),
      preload: [user: {user, strava: strava}],
      order_by: n.inserted_at
    )
    |> Repo.all()
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

  def get_ngo_by_slug(slug, preloads \\ [:ngo_chals]) do
    ngo =
      from(n in NGO,
        where: n.slug == ^slug,
        left_join: challenges in assoc(n, :ngo_chals),
        on: challenges.ngo_id == n.id and challenges.status == ^"active",
        preload: ^preloads,
        group_by: [n.id],
        select: %{
          n
          | active_challenges: count(challenges.id),
            utc_launch_date: n.launch_date,
            launch_date: fragment("? at time zone 'utc'", n.launch_date),
            pre_registration_start_date:
              fragment("? at time zone 'utc'", n.pre_registration_start_date)
        }
      )
      |> Repo.one()

    case Timex.is_valid?(ngo.pre_registration_start_date) and Timex.is_valid?(ngo.launch_date) do
      true ->
        ngo
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(ngo.pre_registration_start_date)
        )
        |> Map.put(:launch_date, Timex.to_datetime(ngo.launch_date))

      _ ->
        ngo
    end
  end

  def get_ngo_by_slug_with_hk_time(slug, preloads \\ [:ngo_chals]) do
    ngo =
      from(n in NGO,
        where: n.slug == ^slug,
        left_join: challenges in assoc(n, :ngo_chals),
        on: challenges.ngo_id == n.id and challenges.status == ^"active",
        preload: ^preloads,
        group_by: [n.id],
        select: %{
          n
          | active_challenges: count(challenges.id),
            utc_launch_date: n.launch_date,
            launch_date:
              fragment("? at time zone 'utc' at time zone 'asia/hong_kong'", n.launch_date),
            pre_registration_start_date:
              fragment(
                "? at time zone 'utc' at time zone 'asia/hong_kong'",
                n.pre_registration_start_date
              )
        }
      )
      |> Repo.one()

    case Timex.is_valid?(ngo.pre_registration_start_date) and Timex.is_valid?(ngo.launch_date) do
      true ->
        ngo
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(ngo.pre_registration_start_date)
        )
        |> Map.put(:launch_date, Timex.to_datetime(ngo.launch_date))

      _ ->
        ngo
    end
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
  Updates a ngo.

  ## Examples

      iex> update_ngo(ngo, %{field: new_value})
      {:ok, %NGO{}}

      iex> update_ngo(ngo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ngo(%NGO{} = ngo, attrs) do
    ngo
    |> NGO.update_changeset(attrs)
    |> switch_pre_registration_date_to_utc()
    |> switch_launch_date_to_utc()
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

  def available_challenge_type_options, do: NGO.challenge_type_options()
end
