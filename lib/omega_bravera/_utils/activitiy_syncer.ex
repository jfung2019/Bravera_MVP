defmodule OmegaBravera.ActivitySyncer do
  require Logger

  alias OmegaBravera.Accounts
  alias OmegaBravera.Challenges.ActivitiesIngestion

  def prepare_challengers() do
    Logger.info("Syncer: Preparing..")
    athletes_ids = Accounts.get_all_athlete_ids()
    challengers =
        Enum.map(athletes_ids, fn athlete_id ->
          challenger = Accounts.get_strava_challengers(athlete_id)
            unless Enum.empty?(challenger), do: challenger
          end)
        |> Enum.filter(&!is_nil(&1))
        |> List.foldl([], &(&1 ++ &2))

    Logger.info("Syncer: I have #{length(athletes_ids)} athlete IDs and #{length(challengers)} are challengers.")

    challengers
  end


  def process_activities(activities_list, page \\ 1)
  def process_activities([head | tail], page) do
    activities = next_activity_page(head, page)
    Logger.info("Syncer: Got #{length(activities)} for challenge ID: #{elem(head, 0)}, page: #{page}")

    process_challenges(elem(head, 0), elem(head, 1), activities)
      if Enum.empty?(activities) do
        process_activities(tail)
      else
        process_activities([head | tail], page + 1)
      end
  end

  def process_activities([], _) do
    []
  end

  def next_activity_page(challenger, page \\ 1) do
    Strava.Activity.list_athlete_activities(%Strava.Pagination{
        per_page: 100,
        page: page
      },
      %{},
      Strava.Client.new(elem(challenger, 1)) # Create a new access_token struct
    )
  end

  # Note: token is only there to satisfy pattern matching for ActivitiesIngestion.process_challenge/2
  def process_challenges(challenge_id, token, activities) do
    Logger.info("Syncer: Processing Activities for Challenge #{challenge_id}...")
    for activity <- activities do
      ActivitiesIngestion.process_challenge({challenge_id, token}, activity)
    end
  end

  def sync() do
    Logger.info("Syncer: Dropping existing active challenges activities")
    Accounts.drop_active_challenges_activities()

    Logger.info("Syncer: Starting ActivitySyncer model...")
    prepare_challengers() |> process_activities()
  end
end
