defmodule OmegaBravera.DailyDigest.Worker do
  import Ecto.Query

  alias OmegaBravera.{
    Repo,
    Challenges.NGOChal,
    Accounts.User,
    Money.Donation,
    Trackers.Strava,
    DailyDigest.Notifier
  }

  def process_digest() do
    new_users = Repo.all(new_users_query())
    new_donors = Repo.all(new_donors_query())
    new_challenges = Repo.all(new_challenges_query())

    challenges_by_new_users = Repo.all(challenges_by_new_users_query(new_users))
    challenges_with_milestones = Repo.all(challenges_with_milestones_query())
    challenges_completed = Repo.all(challenges_completed_query())

    challenges = Repo.all(NGOChal)

    %{signups: new_users}
    |> Map.put(:new_donors, new_donors)
    |> Map.put(:new_challenges, new_challenges)
    |> Map.put(:challenges_new_users, challenges_by_new_users)
    |> Map.put(:challenges_milestones, challenges_with_milestones)
    |> Map.put(:challenges_completed, challenges_completed)
    |> Notifier.send_digest_email()
  end

  defp get_ids(things), do: Enum.map(things, &Map.get(&1, :id))

  def new_users_query do
    from(user in User,
      join: strava in Strava,
      on: strava.user_id == user.id,
      where: user.inserted_at >= ^start_date() and user.inserted_at < ^end_date(),
      where: strava.inserted_at >= ^start_date() and strava.inserted_at < ^end_date(),
      preload: [:strava]
    )
  end

  def new_donors_query do
    from(user in User,
      join: donation in Donation,
      on: donation.user_id == user.id,
      where: donation.inserted_at >= ^start_date() and donation.inserted_at < ^end_date(),
      preload: [donations: [ngo_chal: [:ngo]]],
      distinct: true
    )
  end

  def new_challenges_query do
    from(challenge in NGOChal,
      where: challenge.inserted_at >= ^start_date() and challenge.inserted_at < ^end_date(),
      preload: [:user, :ngo]
    )
  end

  def challenges_by_new_users_query(users) do
    Ecto.Query.where(new_challenges_query(), [c], c.user_id in ^get_ids(users))
  end

  def challenges_with_milestones_query do
    from(challenge in NGOChal,
      join: donation in Donation,
      on: donation.ngo_chal_id == challenge.id,
      where:
        donation.updated_at >= ^start_date() and donation.updated_at < ^end_date() and
          donation.milestone > 1 and donation.status == "charged",
      distinct: true
    )
  end

  def challenges_completed_query do
    from(challenge in NGOChal,
      where:
        challenge.status == "complete" and challenge.updated_at >= ^start_date() and
          challenge.updated_at < ^end_date()
    )
  end

  def start_date() do
    end_date()
    |> Timex.shift(days: -1)
  end

  # Returns the utc timestamp for today at 6am HKT which ends up being 22h UTC
  def end_date do
    {Timex.to_erl(Timex.today()), {22, 0, 0}}
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
  end
end
