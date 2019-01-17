defmodule OmegaBravera.DailyDigest.NotifierTest do
  use OmegaBravera.DataCase, async: true
  import OmegaBravera.Factory

  alias OmegaBravera.DailyDigest.Notifier

  test "signups_digest_email/1 builds the daily signups digest email without attachments" do
    params = %{
      signups: [],
      new_challenges: [],
      challenges_new_users: [],
      challenges_milestones: [],
      challenges_completed: [],
      new_donors: []
    }

    email = Notifier.signups_digest_email(params)

    assert hd(email.content)[:value] ==
             "In the past 24h we've had 0 signups, 0 new donors, 0 new Challenges, out of which, 0 is by new users. " <>
               "We've also had 0 challenges with completed milestones out of which 0 reached completion. " <>
               "Attached are the relevant CSV files for the new entries"

    assert email.from == %{email: "admin@bravera.co", name: "Bravera"}
    assert email.subject == "Daily Activity Digest"
    assert email.to == [%{email: "admin@bravera.co"}]
  end

  test "signups_digest_email/1 builds the daily signups digest email with attachments" do
    strava = insert(:strava)

    donor = insert(:user)
    insert_list(4, :donation, %{user: donor})

    params = %{
      signups: [strava.user, insert(:strava, %{athlete_id: 33_762_321}).user, insert(:strava, %{athlete_id: 33_762_123}).user],
      new_challenges: [insert(:ngo_challenge), insert(:ngo_challenge, %{user: strava.user})],
      challenges_new_users: [],
      challenges_milestones: [],
      challenges_completed: [],
      new_donors: [donor]
    }

    email = Notifier.signups_digest_email(params)

    assert hd(email.content)[:value] ==
             "In the past 24h we've had 3 signups, 1 new donors, 2 new Challenges, out of which, 0 is by new users. " <>
               "We've also had 0 challenges with completed milestones out of which 0 reached completion. " <>
               "Attached are the relevant CSV files for the new entries"

    assert length(email.attachments) == 3
  end

  test "send_digest_email/1 sends the daily digest email" do
    params = %{
      signups: [],
      new_challenges: [],
      challenges_new_users: [],
      challenges_milestones: [],
      challenges_completed: [],
      new_donors: []
    }

    assert Notifier.send_digest_email(params)[:mailer_result] == :ok
  end
end
