defmodule OmegaBravera.Challenges.Notifier do
  alias OmegaBravera.{Challenges.NGOChal, Challenges.Activity, Repo, Money.Donation, Accounts.User}
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
    |> Email.add_substitution("-challengeURL-", "#{Application.get_env(:omega_bravera, :app_base_url)}#{path}")
    |> Email.add_substitution("-startDate-", Timex.format!(challenge.start_date, "%Y-%m-%d", :strftime))
    |> Email.add_substitution("-challengeName-", challenge.slug)
    |> Email.add_substitution("-ngoName-", challenge.ngo.name)
    |> Email.add_substitution("-daysDuration-", "#{challenge.duration} days")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-challengeMilestones-", "#{NGOChal.milestones_string(challenge)}")
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_activity_completed_email(%NGOChal{} = chal, %Activity{} = activity) do
    chal
    |> Repo.preload([:user, :ngo])
    |> activity_completed_email(activity)
    |> Mailer.send()
  end

  def activity_completed_email(%NGOChal{} = challenge, %Activity{} = activity) do
    Email.build()
    |> Email.put_template("d92b0884-818d-4f54-926a-a529e5caa7d8")
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-activityDistance-", "#{activity.distance} Km")
    |> Email.add_substitution("-completedChallengeDistance-", "#{challenge.distance_covered} Km")
    |> Email.add_substitution("-challengeDistance-", "#{challenge.distance_target} Km")
    |> Email.add_substitution("-timeRemaining-", "#{remaining_time(challenge)}")
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_donor_milestone_email(%Donation{} = donation) do
    donation
    |> Repo.preload([ngo_chal: [:user, :ngo], user: [], ngo: []])
    |> donor_milestone_email()
    |> Mailer.send()
  end

  def donor_milestone_email(%Donation{} = donation) do
    Email.build()
    |> Email.put_template("c8573175-93a6-4f8c-b1bb-9368ad75981a")
    |> Email.add_substitution("-donorName-", donation.user.firstname)
    |> Email.add_substitution("-participantName-", donation.ngo_chal.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(donation.ngo_chal))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donation.user.email)
  end

  def send_participant_milestone_email(%NGOChal{} = challenge) do
    challenge
    |> Repo.preload([:user])
    |> participant_milestone_email()
    |> Mailer.send()
  end

  def participant_milestone_email(%NGOChal{} = challenge) do
    Email.build()
    |> Email.put_template("e4c626a0-ad9a-4479-8228-6c02e7318789")
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_participant_inactivity_email(%NGOChal{} = challenge) do
    challenge
    |> Repo.preload([:user, :ngo])
    |> participant_inactivity_email()
    |> Mailer.send()
  end

  def participant_inactivity_email(%NGOChal{} = challenge) do
    Email.build()
    |> Email.put_template("1395a042-ef5a-48a5-b890-c6340dd8eeff")
    |> Email.add_substitution("-firstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(challenge.user.email)
  end

  def send_donor_inactivity_email(%NGOChal{} = challenge, %User{} = donor) do
    challenge
    |> Repo.preload([:user, :ngo])
    |> donor_inactivity_email(donor)
    |> Mailer.send()
  end

  def donor_inactivity_email(%NGOChal{} = challenge, %User{} = donor) do
    Email.build()
    |> Email.put_template("b91a66e1-d7f5-404f-804a-9a21f4ec70d4")
    |> Email.add_substitution("-donorName-", donor.firstname)
    |> Email.add_substitution("-participantName-", User.full_name(challenge.user))
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(donor.email)
  end

  def send_buddies_invite_email(%NGOChal{} = challenge, buddies) do
    buddies
    |> Enum.map(&buddy_invite_email(challenge, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.each(&Mailer.send/1)
  end

  def buddy_invite_email(%NGOChal{} = challenge, %{"name" => name, "email" => email}) when not is_nil(name) and not is_nil(email) and name != "" and email != "" do
    Email.build()
    |> Email.put_template("58de1c57-8028-4e0d-adb2-7349c01cf233")
    |> Email.add_substitution("-buddyName-", name)
    |> Email.add_substitution("-participantName-", User.full_name(challenge.user))
    |> Email.add_substitution("-participantFirstName-", challenge.user.firstname)
    |> Email.add_substitution("-challengeURL-", challenge_url(challenge))
    |> Email.put_from("admin@bravera.co", "Bravera")
    |> Email.add_bcc("admin@bravera.co")
    |> Email.add_to(email)
  end

  def buddy_invite_email(_, _) do
  end

  defp challenge_url(challenge) do
    "#{Application.get_env(:omega_bravera, :app_base_url)}/#{challenge.ngo.slug}/#{challenge.slug}"
  end

  defp remaining_time(%NGOChal{end_date: end_date}) do
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
end
