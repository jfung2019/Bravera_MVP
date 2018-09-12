defmodule OmegaBravera.Accounts.SignupsTrackingWorkerTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Accounts.SignupsTrackingWorker

  test "process_signups/0 finds all new users details, encodes them as csv and sends the email" do
    older_user = insert(:user, %{inserted_at: Timex.shift(Timex.now, days: -2)})
    new_user = insert(:user, %{inserted_at: Timex.shift(Timex.now, days: -1)})
    strava = insert(:strava, %{user: new_user})

    {mailer_result, users, csv} = SignupsTrackingWorker.process_signups()

    assert length(users) == 1
    assert hd(users).id == new_user.id
    assert is_nil(csv) == false
    assert mailer_result == :ok
  end
end
