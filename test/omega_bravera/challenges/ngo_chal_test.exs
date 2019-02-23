defmodule OmegaBravera.Challenges.NGOChalTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges.NGOChal, Slugify}

  test "changeset/2 is invalid if not provided the required attributes" do
    assert NGOChal.changeset(%NGOChal{}, %{"activity_type" => "Walk"}).valid? == false
  end

  test "create_changeset/2 sets the start and end date based on the specified challenge duration" do
    user = insert(:user)
    ngo = insert(:ngo, user: user)

    attrs = %{
      "activity_type" => "Walk",
      "money_target" => Decimal.new(10000),
      "distance_target" => 50,
      "duration" => 50,
      "ngo_id" => ngo.id,
      "user_id" => user.id,
      "slug" => Slugify.gen_random_slug(user.firstname),
      "type" => "PER_MILESTONE"
    }

    changeset = NGOChal.create_changeset(%NGOChal{}, ngo, attrs)

    assert changeset.valid? == true
    assert changeset.changes[:start_date] != nil
    assert changeset.changes[:end_date] != nil
  end

  describe "activity_completed_changeset/2" do
    test "updates the distance_covered" do
      challenge = insert(:ngo_challenge, %{distance_covered: Decimal.from_float(1.23)})

      changeset =
        NGOChal.activity_completed_changeset(challenge, %{distance: Decimal.from_float(4.32)})

      assert changeset.changes[:distance_covered] == Decimal.from_float(5.55)
      assert changeset.changes[:status] == nil
    end

    test "sets the Challenge as completed once the distance_covered > target_distance" do
      challenge = insert(:ngo_challenge)
      completed_distance = challenge.distance_target * 1000 + 1

      changeset =
        NGOChal.activity_completed_changeset(challenge, %Strava.Activity{
          distance: completed_distance
        })

      assert changeset.changes[:status] == "complete"
    end

    test "resets :last_activity_received, :participant_notified_of_inactivity, :donor_notified_of_inactivity" do
      now = Timex.now() |> DateTime.truncate(:second)

      challenge =
        insert(:ngo_challenge, %{
          last_activity_received: Timex.shift(now, days: -9),
          participant_notified_of_inactivity: true,
          donor_notified_of_inactivity: true
        })

      changeset =
        NGOChal.activity_completed_changeset(challenge, %Strava.Activity{distance: 3215})

      assert changeset.changes[:participant_notified_of_inactivity] == false
      assert changeset.changes[:donor_notified_of_inactivity] == false
      # timestamp set a bit ahead of the start of the test, 0 == equal, 1 == after
      assert Timex.compare(changeset.changes[:last_activity_received], now) > -1
    end
  end

  test "participant_inactivity_notification_changeset/1 sets the field to true" do
    challenge = insert(:ngo_challenge)
    changeset = NGOChal.participant_inactivity_notification_changeset(challenge)

    assert changeset.changes[:participant_notified_of_inactivity] == true
  end

  test "donor_inactivity_notification_changeset/1 sets the field to true" do
    challenge = insert(:ngo_challenge)
    changeset = NGOChal.donor_inactivity_notification_changeset(challenge)

    assert changeset.changes[:donor_notified_of_inactivity] == true
  end

  test "milestones_string/1 returns the milestones for a challenge" do
    challenge = build(:ngo_challenge, %{distance_target: 150})

    assert NGOChal.milestones_string(challenge) == "50 Km, 100 Km, 150 Km"
  end
end
