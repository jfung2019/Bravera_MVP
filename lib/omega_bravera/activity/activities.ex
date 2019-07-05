defmodule OmegaBravera.Activity.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Activity.ActivityAccumulator

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
