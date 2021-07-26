defmodule OmegaBravera.Points do
  @moduledoc """
  Points Context.
  """
  import Ecto.Query
  require Logger
  alias OmegaBravera.{Repo, Accounts}
  alias OmegaBravera.Points.{Point, Notifier}
  alias OmegaBravera.Activity.ActivityAccumulator

  @doc """
  Creates a changeset from a Point struct.
  Used in new form for admin panel.
  """
  def change_point(%Point{} = point), do: Point.changeset(point)

  def create_points_from_activity(activity, user_with_points) do
    %Point{}
    |> Point.activity_points_changeset(activity, user_with_points)
    |> Repo.insert()
  end

  @doc """
  Adds points to a user using an activity.
  """
  @spec add_points_to_user_from_activity(OmegaBravera.Activity.ActivityAccumulator.t()) ::
          {:ok, Point.t()} | {:error, any}
  def add_points_to_user_from_activity(%{user_id: user_id} = activity) do
    user_with_points = Accounts.get_user_with_todays_points(user_id, activity.start_date)

    case create_points_from_activity(activity, user_with_points) do
      {:ok, _point} = ok_tuple ->
        Logger.info(
          "Activity Create Queue: Successfully created points for activity: #{activity.id}"
        )

        # TODO: Find a way to make this a trigger
        Absinthe.Subscription.publish(
          OmegaBraveraWeb.Endpoint,
          %{
            balance: total_points(user_id),
            history: user_points_history_summary(user_id)
          },
          live_points: user_id
        )

        ok_tuple

      {:error, reason} = error_tuple ->
        Logger.warn(
          "Activity Create Queue: Could not create points for activity, reason: #{inspect(reason)}"
        )

        error_tuple
    end
  end

  def create_bonus_points(attrs \\ %{}) do
    %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get a breakdown of all points in a certain day by a user.
  """
  def point_breakdown_by_day(day, user_id) do
    from(p in Point,
      where: p.user_id == ^user_id and fragment("cast(? as date)", p.inserted_at) == ^day
    )
    |> Repo.all()
  end

  @doc """
  Gets total points for user minus any spent points.
  """
  def total_points(user_id),
    do:
      Repo.aggregate(
        from(p in Point, where: p.user_id == ^user_id, select: coalesce(p.value, 0.0)),
        :sum,
        :value
      ) || Decimal.from_float(0.0)

  @doc """
  Gets summary by day of user points with the points separated out.
  """
  def user_points_history_summary(user_id) do
    from(
      p in Point,
      as: :point,
      left_lateral_join:
        aa in subquery(
          from(a in ActivityAccumulator,
            where:
              a.user_id == ^user_id and
                fragment("?::date = ?::date", parent_as(:point).inserted_at, a.start_date),
            group_by: fragment("?::date", a.start_date),
            select: %{
              distance: coalesce(sum(a.distance), 0),
              start_date: fragment("?::date", a.start_date)
            }
          )
        ),
      on: fragment("?::date = ?::date", p.inserted_at, aa.start_date),
      where: p.user_id == ^user_id,
      order_by: [desc: fragment("CAST(? AS DATE)", p.inserted_at)],
      group_by: [fragment("CAST(? AS DATE)", p.inserted_at), aa.distance],
      select: %{
        neg_value: fragment("sum(case when ? < 0 then ? else 0 end)", p.value, p.value),
        pos_value: fragment("sum(case when ? > 0 then ? else 0 end)", p.value, p.value),
        distance: aa.distance,
        inserted_at: fragment("CAST(? AS DATE)", p.inserted_at)
      }
    )
    |> Repo.all()
  end

  def get_user_points_one_week(user_id) do
    today = Timex.now() |> DateTime.to_date()
    one_week_ago = today |> Timex.shift(days: -7)

    from(p in Point,
      where:
        fragment("cast(? as date) BETWEEN ? and ?", p.inserted_at, ^one_week_ago, ^today) and
          p.user_id == ^user_id,
      select: %{value: sum(p.value), day: fragment("cast(inserted_at as date) as day")},
      group_by: fragment("day")
    )
    |> Repo.all()
  end

  def do_deduct_points_from_user(user, offer) do
    %Point{}
    |> Point.deduct_points_changeset(offer, user)
    |> Repo.insert()
  end

  @doc """
  Allows giving of points to a user from an organization perspective.
  """
  @spec add_organization_points(String.t(), map()) ::
          {:error, Ecto.Changeset.t()} | {:ok, Point.t()}
  def add_organization_points(organization_id, attrs) do
    Repo.transaction(fn ->
      changeset =
        %Point{}
        |> Point.organization_changeset(Map.put(attrs, "organization_id", organization_id))

      case Repo.insert(changeset) do
        {:ok, points} = ok_tuple ->
          if Accounts.get_remaining_points_for_today_for_organization(organization_id) < 0 do
            changeset
            |> Ecto.Changeset.put_change(:value, "too many points")
            |> Repo.rollback()
          else
            Task.Supervisor.start_child(OmegaBravera.TaskSupervisor, fn ->
              user = Accounts.get_user!(points.user_id)
              current_balance = total_points(user.id)

              :ok =
                Notifier.send_points_updated_notification_from_org(
                  user,
                  current_balance,
                  points.value
                )
            end)

            ok_tuple
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end
end
