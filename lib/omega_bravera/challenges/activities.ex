defmodule OmegaBravera.Challenges.Activities do
  require Logger
  alias OmegaBravera.{Accounts, Money, StripeHelpers, Fundraisers, Challenges, Challenges.NGOChal, Donations.Processor, Money.Donation, Repo}

  def process(_) do
  end

  def process(%{"aspect_type" => "create", "object_type" => "activity"} = params) do
    params["owner_id"]
    |> Accounts.get_strava_challengers()
    |> process_challenges(params)
  end

  defp process_challenges([hd | _] = challenges, params) do
    activity = Strava.Activity.retrieve(params["object_id"], strava_client(hd))
    Enum.map(challenges, &process_challenge(&1, activity))
  end

  def process_challenge({challenge_id, _}, %Strava.Activity{distance: distance} = strava_activity) when distance > 0 and is_integer(challenge_id) do
    challenge = Challenges.get_ngo_chal!(challenge_id)


    activity = create_activity(strava_activity, challenge)
    update_challenge(challenge, activity)


    Challenges.Notifier.send_activity_completed_email(challenge, activity)

    donations = Money.chargeable_donations_for_challenge(challenge)

    charges_result =
      donations
      |> notify_participant_of_milestone(challenge)
      |> Enum.map(&notify_donor_and_charge_donation/1)

    if length(charges_result) == length(donations) and Enum.all?(charges_result, &match?({:ok, :donation_charged}, &1)) do
      {:ok, :challenge_updated}
    else
      {:error, :uncharged_donations}
    end
  end

  def process_challenge(_, _) do
    {:ok, :nothing_done}
  end

  defp notify_participant_of_milestone(donations, challenge) do
    if length(donations) > 0 do
      Challenges.Notifier.send_participant_milestone_email(challenge)
    end

    donations
  end

  def notify_donor_and_charge_donation(%Donation{} = donation) do
    Challenges.Notifier.send_donor_milestone_email(donation)
    Processor.charge_donation(donation)
  end

  defp create_activity(activity, challenge) do
    changeset = Challenges.Activity.create_changeset(activity, challenge)

    case Repo.insert(changeset) do
      {:ok, activity} -> activity
      {:error, _} -> nil
    end
  end

  defp update_challenge(challenge, activity) do
    challenge
    |> NGOChal.activity_completed_changeset(activity)
    |> Repo.update()
  end

  defp strava_client({_, token}), do: Strava.Client.new(token)
end
