defmodule OmegaBravera.Challenges.Notifier do
  alias OmegaBravera.{Challenges.NGOChal, Repo}
  alias SendGrid.{Email, Mailer}

  def send_challenge_signup_email(%NGOChal{} = challenge, path) do
    challenge
    |> Repo.preload([:user, :ngo])
    |> challenge_signup_email(path)
    |> Mailer.send()
  end

  def challenge_signup_email(%NGOChal{} = challenge, path) do
    Email.build()
    |> Email.put_template("e5402f0b-a2c2-4786-955b-21d1cac6211d")
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", "http://bravera.co#{path}")
    |> Email.add_substitution("-startDate-", Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime))
    |> Email.add_substitution("-challengeName-", challenge.slug)
    |> Email.add_substitution("-ngoName-", challenge.ngo.name)
    |> Email.add_substitution("-daysDuration-", "#{challenge.duration} days")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-challengeMilestones-", "#{NGOChal.milestones_string(challenge)}")
    |> Email.put_from("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_activity_completed_email(%NGOChal{} = chal, %Strava.Activity{} = activity) do
    chal
    |> Repo.preload([:user, :ngo])
    |> activity_completed_email(activity)
    |> Mailer.send()
  end

  def activity_completed_email(%NGOChal{} = challenge, %Strava.Activity{} = activity) do
    Email.build()
    |> Email.put_template("d92b0884-818d-4f54-926a-a529e5caa7d8")
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-activityDistance-", "#{activity_distance(activity)} Km")
    |> Email.add_substitution("-completedChallengeDistance-", "#{challenge.distance_covered} Km")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-timeRemaining-", "#{remaining_time(challenge)}")
    |> Email.add_substitution("-challengeURL-", "http://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}")
    |> Email.put_from("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_milestone_completion_emails(_, _) do
  end

  def remaining_time(%NGOChal{end_date: end_date}) do
    now = Timex.now
    remaining_days = Timex.diff(end_date, now, :days)

    cond do
      (diff = Timex.diff(end_date, now, :days)) > 0 ->
        "#{diff} days"
      (diff = Timex.diff(end_date, now, :hours)) > 0 ->
        "#{diff} hours"
      (diff = Timex.diff(end_date, now, :minutes)) > 0 ->
        "#{diff} minutes"
      true ->
        "0 minutes"
    end
  end

  defp activity_distance(%Strava.Activity{distance: d}) do
    Decimal.div(Decimal.new(d), Decimal.new(1000))
  end
end
