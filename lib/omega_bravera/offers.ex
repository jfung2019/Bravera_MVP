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

  def list_offers(hidden \\ false) do
    # The problem: total_pledged_secured_query + total_distance_calories_challenges_query + ngos_with_stats query for offers
    # with stats and do that correctly. However, any new Offer or an existing Offer without challenges, activities, and donations
    # are not included.

    total_distance_calories_challenges_query =
      from(
        offer in Offer,
        where: offer.hidden == ^hidden,
        join: offer_challenge in assoc(offer, :offer_challenges),
        left_join: activity in assoc(offer_challenge, :offer_challenge_activities),
        group_by: offer.id,
        select: %{
          offer_id: offer.id,
          total_distance_covered: fragment("round(sum(coalesce(?, 0)), 0)", activity.distance),
          total_calories: fragment("round(sum(coalesce(?, 0)), 0)", activity.calories),
          num_of_challenges: fragment("round(count( distinct coalesce(?, 0)), 0)", offer_challenge.id)
        }
      )

    ngos_with_stats =
      from(
        offer in Offer,
        where: offer.hidden == ^hidden,
        join:
          offer_distance_calories_challenges in subquery(total_distance_calories_challenges_query),
        on: offer.id == offer_distance_calories_challenges.offer_id,
        order_by: [desc: offer.id],
        select: %{
          offer
          | total_distance_covered: offer_distance_calories_challenges.total_distance_covered,
            total_calories: offer_distance_calories_challenges.total_calories,
            num_of_challenges: offer_distance_calories_challenges.num_of_challenges
        }
      )
      |> Repo.all()

    # Hacky solution:
    ngos_with_stats_ids = ngos_with_stats |> Enum.map(& &1.id)

    ngos_without_stats =
      from(
        offer in Offer,
        where: offer.hidden == ^hidden and offer.id not in ^ngos_with_stats_ids,
        order_by: [desc: offer.id]
      )
      |> Repo.all()

    offers = ngos_with_stats ++ ngos_without_stats

    # Sort by desc: id.
    Enum.sort(offers, &(&1.id >= &2.id))
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

  def get_offer_by_slug(slug, preloads \\ [:offer_challenges]) do
    offer =
      from(o in Offer,
        where: o.slug == ^slug,
        left_join: offer_challenges in assoc(o, :offer_challenges),
        on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
        preload: ^preloads,
        group_by: [o.id],
        select: %{
          o |
            active_offer_challenges: count(offer_challenges.id),
            launch_date: o.launch_date,
            pre_registration_start_date:
              fragment("? at time zone 'utc'", o.pre_registration_start_date)
        }
      )
      |> Repo.one()

    cond do
      offer == nil ->
        nil

      Timex.is_valid?(offer.pre_registration_start_date) and Timex.is_valid?(offer.launch_date) ->
        offer
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(offer.pre_registration_start_date)
        )
        |> Map.put(:launch_date, Timex.to_datetime(offer.launch_date))

      true ->
        offer
    end
  end

  def get_offer_by_slug_with_hk_time(slug, preloads \\ [:offer_challenges]) do
    offer =
      from(o in Offer,
        where: o.slug == ^slug,
        left_join: offer_challenges in assoc(o, :offer_challenges),
        on: offer_challenges.offer_id == o.id and offer_challenges.status == ^"active",
        preload: ^preloads,
        group_by: [o.id],
        select: %{
          o
          | active_offer_challenges: count(offer_challenges.id),
            launch_date: o.launch_date,
            launch_date:
              fragment("? at time zone 'utc' at time zone 'asia/hong_kong'", o.launch_date),
            pre_registration_start_date:
              fragment(
                "? at time zone 'utc' at time zone 'asia/hong_kong'",
                o.pre_registration_start_date
              )
        }
      )
      |> Repo.one()

    case Timex.is_valid?(offer.pre_registration_start_date) and Timex.is_valid?(offer.launch_date) do
      true ->
        offer
        |> Map.put(
          :pre_registration_start_date,
          Timex.to_datetime(offer.pre_registration_start_date)
        )
        |> Map.put(:launch_date, Timex.to_datetime(offer.launch_date))

      _ ->
        offer
    end
  end

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

  alias OmegaBravera.Offers.OfferChallenge

  @doc """
  Returns the list of offer_challenges.

  ## Examples

      iex> list_offer_challenges()
      [%OfferChallenge{}, ...]

  """
  def list_offer_challenges do
    Repo.all(OfferChallenge)
  end

  def list_offers_preload() do
    from(
      o in Offer,
      join: user in assoc(o, :user),
      join: strava in assoc(user, :strava),
      preload: [user: {user, strava: strava}],
      order_by: o.inserted_at
    )
    |> Repo.all()
  end

  @doc """
  Gets a single offer_challenge.

  Raises `Ecto.NoResultsError` if the Offer challenge does not exist.

  ## Examples

      iex> get_offer_challenge!(123)
      %OfferChallenge{}

      iex> get_offer_challenge!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offer_challenge!(id), do: Repo.get!(OfferChallenge, id)

  @doc """
  Creates a offer_challenge.

  ## Examples

      iex> create_offer_challenge(%{field: value})
      {:ok, %OfferChallenge{}}

      iex> create_offer_challenge(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_offer_challenge(attrs \\ %{}) do
    %OfferChallenge{}
    |> OfferChallenge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a offer_challenge.

  ## Examples

      iex> update_offer_challenge(offer_challenge, %{field: new_value})
      {:ok, %OfferChallenge{}}

      iex> update_offer_challenge(offer_challenge, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offer_challenge(%OfferChallenge{} = offer_challenge, attrs) do
    offer_challenge
    |> OfferChallenge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a OfferChallenge.

  ## Examples

      iex> delete_offer_challenge(offer_challenge)
      {:ok, %OfferChallenge{}}

      iex> delete_offer_challenge(offer_challenge)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offer_challenge(%OfferChallenge{} = offer_challenge) do
    Repo.delete(offer_challenge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offer_challenge changes.

  ## Examples

      iex> change_offer_challenge(offer_challenge)
      %Ecto.Changeset{source: %OfferChallenge{}}

  """
  def change_offer_challenge(%OfferChallenge{} = offer_challenge) do
    OfferChallenge.changeset(offer_challenge, %{})
  end
end
