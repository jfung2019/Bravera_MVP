defmodule OmegaBravera.Activity.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.{Activity}
  alias OmegaBravera.Activity.ActivityAccumulator

  def list_activities_added_by_admin() do
    from(
      activity in Activity,
      where: not is_nil(activity.admin_id),
      left_join: challenge in assoc(activity, :challenge),
      left_join: ngo in assoc(challenge, :ngo),
      left_join: user in assoc(activity, :user),
      preload: [challenge: {challenge, ngo: ngo}, user: user],
      order_by: [desc: :id]
    )
    |> Repo.all()
  end

  def create_activity(activity, user) do
    changeset =
      if Map.has_key?(activity, :admin_id) do
        ActivityAccumulator.create_activity_by_admin_changeset(activity, user, activity.admin_id)
      else
        ActivityAccumulator.create_changeset(activity, user)
      end

    Repo.insert(changeset)
  end

  def get_activity!(id) do
    from(a in ActivityAccumulator, where: a.id == ^id) |> Repo.one()
  end
end
