defmodule OmegaBravera.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.{Activity, NGOChal}

  def list_activities_added_by_admin() do
    from(
      a in Activity,
      where: a.added_by_admin == true
    )
    |> Repo.all()
  end

  def create_activity(%Strava.Activity{} = strava_activity, %NGOChal{} = challenge) do
    strava_activity
    |> Activity.create_changeset(challenge)
    |> Repo.insert()
  end
end
