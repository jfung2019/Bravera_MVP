defmodule OmegaBravera.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Challenges.{Activity}

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
end
