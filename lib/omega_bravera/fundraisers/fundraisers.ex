defmodule OmegaBravera.Fundraisers do
  @moduledoc """
  The Fundraisers context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.{
    Fundraisers.NGO,
    Money.Donation,
    Challenges.Activity
  }

  # Get a user's causes by user_id

  def get_ngos_by_user(user_id) do
    from(ngo in NGO, where: ngo.user_id == ^user_id) |> Repo.all()
  end

  def get_donations_for_ngo(slug) do
    from(
      n in NGO,
      where: n.slug == ^slug,
      left_join: donations in assoc(n, :donations),
      on: donations.status == "charged",
      left_join: donor in assoc(donations, :donor),
      left_join: ngo_chal in assoc(donations, :ngo_chal),
      left_join: participant in assoc(ngo_chal, :user),
      preload: [donations: {donations, donor: donor, ngo_chal: {ngo_chal, user: participant}}]
    )
    |> Repo.one()
  end

  def get_monthly_donations_for_ngo(slug, start_date, end_date) do
    from(
      n in NGO,
      where: n.slug == ^slug,
      join: donations in assoc(n, :donations),
      on:
        donations.status == "charged" and donations.charged_at >= ^start_date and
          donations.charged_at <= ^end_date,
      join: donor in assoc(donations, :donor),
      join: ngo_chal in assoc(donations, :ngo_chal),
      join: participant in assoc(ngo_chal, :user),
      select: [
        ngo_chal.slug,
        donations.charge_id,
        fragment("to_char(?, 'YYYY-MM-DD HH:MI')", donations.charged_at),
        fragment("concat(?, ' ', ?)", participant.firstname, participant.lastname),
        fragment("concat(?, ' ', ?)", donor.firstname, donor.lastname),
        donor.email,
        donations.milestone,
        ngo_chal.default_currency,
        fragment("ROUND((? * ?), 1)", donations.charged_amount, donations.exchange_rate),
        fragment(
          "ROUND(((CASE WHEN ? = 'PER_KM' THEN charged_amount * exchange_rate ELSE amount * exchange_rate END) * 0.034) + 2.35, 1)",
          ngo_chal.type
        ),
        fragment(
          "ROUND((CASE WHEN ? = 'PER_KM' THEN charged_amount * exchange_rate ELSE amount * exchange_rate END) * 0.06, 1)",
          ngo_chal.type
        ),
        fragment(
          "CASE
              WHEN ? = 'PER_KM' THEN
                ROUND(((charged_amount * exchange_rate) - (((charged_amount * exchange_rate) * 0.034) + 2.35)) - ((charged_amount * exchange_rate) * 0.06), 1)
              ELSE
                ROUND(((charged_amount * exchange_rate) - (((amount * exchange_rate) * 0.034) + 2.35)) - ((amount * exchange_rate) * 0.06), 1)
            END",
          ngo_chal.type
        )
      ]
    )
    |> Repo.all()
  end

  def get_ngo_with_stats(slug, preloads \\ [:ngo_chals]) do
    case get_ngo_by_slug(slug, preloads) do
      nil ->
        nil

      ngo ->
        total_pledged =
          Repo.one(
            from(
              donation in Donation,
              where: donation.ngo_id == ^ngo.id,
              select:
                fragment(
                  "SUM( CASE WHEN km_distance IS NOT NULL THEN amount * km_distance ELSE amount END )"
                )
            )
          )

        total_secured =
          Repo.aggregate(
            from(
              donation in Donation,
              where: donation.ngo_id == ^ngo.id
            ),
            :sum,
            :charged_amount
          )

        calories_and_activities_query =
          from(
            activity in Activity,
            join: challenge in assoc(activity, :challenge),
            where: challenge.ngo_id == ^ngo.id and activity.challenge_id == challenge.id
          )

        total_distance_covered = Repo.aggregate(calories_and_activities_query, :sum, :distance)
        total_calories = Repo.aggregate(calories_and_activities_query, :sum, :calories)

        %{
          ngo
          | total_pledged: total_pledged,
            total_secured: total_secured,
            num_of_challenges: Enum.count(ngo.ngo_chals),
            total_distance_covered: Decimal.round(total_distance_covered || Decimal.new(0)),
            total_calories: total_calories
        }
    end
  end

  def list_ngos(hidden \\ false, preloads \\ []) do
    # The problem: total_pledged_secured_query + total_distance_calories_challenges_query + ngos_with_stats query for ngos
    # with stats and do that correctly. However, any new NGO or an existing NGO without challenges, activities, and donations
    # are not included.

    total_pledged_secured_query =
      from(
        donation in Donation,
        group_by: donation.ngo_id,
        select: %{
          ngo_id: donation.ngo_id,
          total_pledged:
            fragment(
              "SUM( CASE WHEN km_distance IS NOT NULL THEN amount * km_distance ELSE amount END )"
            ),
          # TODO: get distance covered and if the challenge type is PER_KM, multiply donation.amount with distance_covered. If not, donation.amount
          total_secured: fragment("round(sum(coalesce(?, 0)), 1)", donation.charged_amount)
        }
      )

    # TODO: For some reason, this subquery is not displaying NGOs with no challenges or even newly created NGOs.
    total_distance_calories_challenges_query =
      from(
        ngo in NGO,
        where: ngo.hidden == ^hidden,
        join: challenge in assoc(ngo, :ngo_chals),
        left_join: activity in assoc(challenge, :activities),
        group_by: ngo.id,
        select: %{
          ngo_id: ngo.id,
          total_distance_covered: fragment("round(sum(coalesce(?, 0)), 0)", activity.distance),
          total_calories: fragment("round(sum(coalesce(?, 0)), 0)", activity.calories),
          num_of_challenges: fragment("round(count( distinct coalesce(?, 0)), 0)", challenge.id)
        }
      )

    ngos_with_stats =
      from(
        ngo in NGO,
        where: ngo.hidden == ^hidden,
        join: ngo_pledged_secured in subquery(total_pledged_secured_query),
        on: ngo.id == ngo_pledged_secured.ngo_id,
        join:
          ngo_distance_calories_challenges in subquery(total_distance_calories_challenges_query),
        on: ngo.id == ngo_distance_calories_challenges.ngo_id,
        preload: ^preloads,
        order_by: [desc: ngo.id],
        select: %{
          ngo
          | total_pledged: ngo_pledged_secured.total_pledged,
            total_secured: ngo_pledged_secured.total_secured,
            total_distance_covered: ngo_distance_calories_challenges.total_distance_covered,
            total_calories: ngo_distance_calories_challenges.total_calories,
            num_of_challenges: ngo_distance_calories_challenges.num_of_challenges
        }
      )
      |> Repo.all()

    # Hacky solution:
    ngos_with_stats_ids = ngos_with_stats |> Enum.map(& &1.id)

    ngos_without_stats =
      from(
        ngo in NGO,
        where: ngo.hidden == ^hidden and ngo.id not in ^ngos_with_stats_ids,
        preload: ^preloads,
        order_by: [desc: ngo.id]
      )
      |> Repo.all()

    ngos = ngos_with_stats ++ ngos_without_stats

    # Sort by desc: id.
    Enum.sort(ngos, &(&1.id >= &2.id))
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

    cond do
      ngo == nil ->
        nil

      Timex.is_valid?(ngo.pre_registration_start_date) and Timex.is_valid?(ngo.launch_date) ->
        ngo
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(ngo.pre_registration_start_date)
        )
        |> Map.put(:launch_date, Timex.to_datetime(ngo.launch_date))

      true ->
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
end
