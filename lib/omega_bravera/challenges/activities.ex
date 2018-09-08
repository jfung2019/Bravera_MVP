defmodule OmegaBravera.Challenges.Activities do
  require Logger
  alias OmegaBravera.{Accounts, Money, StripeHelpers, Fundraisers, Challenges, Challenges.NGOChal, Donations.Processor, Money.Donation}

  def process(_) do
  end

  def process(%{"aspect_type" => "create", "object_type" => "activity"} = params) do
    params["owner_id"]
    |> Accounts.get_strava_challengers()
    |> process_challengers(params)
  end

  defp process_challengers([hd | _] = challengers, params) do
    activity = Strava.Activity.retrieve(params["object_id"], strava_client(hd))
    Enum.map(challengers, &process_challenger(&1, activity))
  end

  defp process_challenger({challenge_id, _}, %Strava.Activity{distance: distance} = activity) when distance > 0 do
    challenge = Challenges.get_ngo_chal!(challenge_id)
    updated_distance = Decimal.add(challenge.distance_covered, activity_distance(activity))

    update_ngo_challenge(challenge, updated_distance)
    Challenges.Notifier.send_activity_completed_email(challenge, activity)

    challenge.id
    |> Money.get_unch_donat_by_ngo_chal()
    |> Enum.filter(&chargeable_donation?(&1, updated_distance))
    |> Enum.map(&notify_milestone_completed_and_charge_donation(&1, challenge)) # group per milestone, send email to participant per milestone and send email to donor per donation charged
  end

  defp notify_milestone_completed_and_charge_donation(%Donation{} = donation, %NGOChal{} = challenge) do
    Challenges.Notifier.send_milestone_completion_emails(donation, challenge)
    Processor.charge_donation(donation)
  end

  defp update_ngo_challenge(%NGOChal{} = challenge, updated_distance) do
    Challenges.update_ngo_chal(challenge, %{distance_covered: updated_distance})

    if completed_challenge?(challenge, updated_distance) do
      Challenges.update_ngo_chal(challenge, %{status: "Complete"})
    end
  end

  defp process_challenger(_, _) do
  end

  defp chargeable_donation?(%Donation{milestone_distance: milestone_distance}, updated_distance) do
    case Decimal.cmp(updated_distance, milestone_distance) do
      :lt -> false
      _ -> true #:gt or :eq
    end
  end

  defp completed_challenge?(%NGOChal{distance_target: target}, updated_distance) do
    case Decimal.cmp(updated_distance, target) do
      :lt -> false
      _ -> true #:gt or :eq
    end
  end

  defp activity_distance(%Strava.Activity{distance: d}) do
    Decimal.div(Decimal.new(d), Decimal.new(1000))
  end

  defp strava_client({_, token}) do
    Strava.Client.new(token)
  end
end
