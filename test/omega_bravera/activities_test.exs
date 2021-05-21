defmodule OmegaBravera.ActivitiesTest do
  use OmegaBravera.DataCase, async: true
  alias OmegaBravera.Activity.Activities
  import OmegaBravera.Factory

  setup do
    start_date = Timex.now() |> DateTime.truncate(:second)
    end_date = start_date |> Timex.shift(hours: 1)
    user = insert(:user)
    device = insert(:device, user_id: user.id)
    {:ok, start_date: start_date, end_date: end_date, user: user, device: device}
  end

  test "can not have overlapping activities", %{
    start_date: start_date,
    end_date: end_date,
    user: user,
    device: device
  } do
    assert {:ok, _} =
             Activities.create_app_activity(
               %{
                 "start_date" => start_date,
                 "end_date" => end_date,
                 "type" => "Walk",
                 "source" => "Watch"
               },
               user.id,
               device.id,
               0
             )

    assert {:error, _} =
             Activities.create_app_activity(
               %{
                 "start_date" => start_date,
                 "end_date" => end_date,
                 "type" => "Walk",
                 "source" => "Watch"
               },
               user.id,
               device.id,
               0
             )

    assert {:error, _} =
             Activities.create_app_activity(
               %{
                 "start_date" => Timex.shift(start_date, minutes: 1),
                 "end_date" => Timex.shift(end_date, minutes: 1),
                 "type" => "Walk",
                 "source" => "Watch"
               },
               user.id,
               device.id,
               0
             )

    assert {:ok, _} =
             Activities.create_app_activity(
               %{
                 "start_date" => end_date,
                 "end_date" => Timex.shift(end_date, minutes: 1),
                 "type" => "Walk",
                 "source" => "Watch"
               },
               user.id,
               device.id,
               0
             )
  end

  test "activities with a start_date but no end_date will use start_date as the end_date", %{
    start_date: start_date,
    user: user,
    device: device
  } do
    assert {:ok, %{end_date: ^start_date}} =
             Activities.create_app_activity(
               %{"start_date" => start_date, "type" => "Walk", "source" => "Watch"},
               user.id,
               device.id,
               0
             )
  end
end
