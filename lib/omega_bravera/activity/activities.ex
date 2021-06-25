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

  def create_app_activity(activity_attrs, user_id, device_id, user_activities) do
    ActivityAccumulator.create_bravera_app_activity(
      activity_attrs,
      user_id,
      device_id,
      user_activities
    )
    |> Repo.insert()
  end

  def create_bravera_pedometer_activity(activity_attrs, user_id, device_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :activity,
      ActivityAccumulator.create_bravera_pedometer_activity(activity_attrs, user_id, device_id)
    )
    |> Ecto.Multi.run(:point, fn _repo, %{activity: activity} ->
      OmegaBravera.Points.add_points_to_user_from_activity(activity)
    end)
    |> Repo.transaction()
  end

  def get_user_activities_at_time(
        %{start_date: start_date, end_date: end_date},
        user_id,
        device_id
      ) do
    from(
      a in ActivityAccumulator,
      where:
        a.user_id == ^user_id and
          a.device_id == ^device_id,
      where: a.start_date >= ^start_date,
      where: a.start_date <= ^end_date,
      where: not is_nil(a.device_id) == true,
      select: count(a.id)
    )
    |> Repo.one()
  end

  def get_latest_device_activity(user_id) do
    from(a in ActivityAccumulator,
      where: a.user_id == ^user_id and not is_nil(a.device_id),
      order_by: [desc: a.end_date],
      limit: 1
    )
    |> Repo.one()
  end
end
