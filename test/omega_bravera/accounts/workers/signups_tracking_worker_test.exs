defmodule OmegaBravera.Accounts.SignupsTrackingWorkerTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Accounts.SignupsTrackingWorker

  test "process_signups/0 finds all new users details, encodes them as csv and sends the email" do
    _older_user = insert(:user, %{inserted_at: inserted_at(21, days: -2)})
    new_user = insert(:user, %{inserted_at: inserted_at(22)}) #just when the timespan starts
    _strava = insert(:strava, %{user: new_user})

    {mailer_result, users, csv} = SignupsTrackingWorker.process_signups()

    assert length(users) == 1
    assert hd(users).id == new_user.id
    assert is_nil(csv) == false
    assert mailer_result == :ok
  end

  test "end_date/0 returns the correct end_date for the window" do
    end_date =
      {Timex.to_erl(Timex.today), {22, 0, 0}}
      |> NaiveDateTime.from_erl!
      |> DateTime.from_naive!("Etc/UTC")

    assert SignupsTrackingWorker.end_date == end_date
  end

  test "start_date/0 returns the correct end_date for the window" do
    start_date = Timex.shift(SignupsTrackingWorker.end_date, days: -1)

    assert SignupsTrackingWorker.start_date == start_date
  end


  defp inserted_at(hour, shift \\ [days: -1]) do
    Timex.Timezone.resolve("UTC", {Timex.to_erl(Timex.today), {hour, 0, 0}})
    |> Timex.shift(shift)
  end
end
