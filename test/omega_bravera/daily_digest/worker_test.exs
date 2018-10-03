defmodule OmegaBravera.DailyDigest.WorkerTest do
  use OmegaBravera.DataCase
  import OmegaBravera.Factory

  alias OmegaBravera.DailyDigest.Worker

  test "process_signups/0 finds all new users signups, all new challenges, all challenges with milestones and all completed challenges" do
    old_user = insert(:user, %{inserted_at: inserted_at(21, days: -3)})
    insert(:strava, %{user: old_user})

    old_donor = insert(:user, %{inserted_at: inserted_at(21, days: -10)})

    # just when the timespan starts
    new_user = insert(:user, %{inserted_at: inserted_at(23)})
    insert(:strava, %{user: new_user})

    new_donor = insert(:user, %{inserted_at: inserted_at(15, days: 0)})
    challenge = insert(:ngo_challenge, %{inserted_at: inserted_at(23), user: old_user})

    insert(:donation, %{
      ngo_chal: challenge,
      milestone: 1,
      status: "charged",
      updated_at: inserted_at(17, days: 0),
      user: new_donor
    })

    challenge_by_new_user =
      insert(:ngo_challenge, %{inserted_at: inserted_at(14, days: 0), user: new_user})

    challenge_with_milestones =
      insert(:ngo_challenge, %{inserted_at: inserted_at(3, days: -20), user: old_user})

    insert(:donation, %{
      ngo_chal: challenge_with_milestones,
      milestone: 2,
      status: "charged",
      updated_at: inserted_at(23),
      user: old_donor
    })

    insert(:donation, %{
      ngo_chal: challenge_with_milestones,
      milestone: 3,
      status: "charged",
      updated_at: inserted_at(21, days: 0),
      user: old_donor
    })

    completed_challenge =
      insert(:ngo_challenge, %{
        inserted_at: inserted_at(3, days: -45),
        status: "complete",
        updated_at: inserted_at(5, days: 0),
        user: old_user
      })

    insert(:donation, %{
      ngo_chal: completed_challenge,
      milestone: 4,
      status: "charged",
      updated_at: inserted_at(5, days: 0),
      user: old_donor
    })

    result = Worker.process_digest()

    assert length(result[:signups]) == 1
    assert hd(result[:signups]).id == new_user.id

    assert length(result[:new_donors]) == 2
    donors = result[:new_donors]

    assert [old_donor.id, new_donor.id] == Enum.map(donors, &Map.get(&1, :id))

    [ch_1, ch_2] = result[:new_challenges]
    assert ch_1.id == challenge.id
    assert ch_2.id == challenge_by_new_user.id

    assert length(result[:challenges_new_users]) == 1
    assert hd(result[:challenges_new_users]).id == challenge_by_new_user.id

    [chm_1, chm_2] = result[:challenges_milestones]

    assert chm_1.id == challenge_with_milestones.id
    assert chm_2.id == completed_challenge.id

    assert length(result[:challenges_completed]) == 1
    assert hd(result[:challenges_completed]).id == completed_challenge.id

    assert result[:mailer_result] == :ok
  end

  test "end_date/0 returns the correct end_date for the window" do
    end_date =
      {Timex.to_erl(Timex.today()), {22, 0, 0}}
      |> NaiveDateTime.from_erl!()
      |> DateTime.from_naive!("Etc/UTC")

    assert Worker.end_date() == end_date
  end

  test "start_date/0 returns the correct end_date for the window" do
    start_date = Timex.shift(Worker.end_date(), days: -1)

    assert Worker.start_date() == start_date
  end

  def inserted_at(hour, shift \\ [days: -1]) do
    Timex.Timezone.resolve("Etc/UTC", {Timex.to_erl(Timex.today()), {hour, 0, 0}})
    |> Timex.shift(shift)
  end
end
