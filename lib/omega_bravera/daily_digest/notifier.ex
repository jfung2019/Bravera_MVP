defmodule OmegaBravera.DailyDigest.Notifier do
  alias OmegaBravera.DailyDigest.Serializers.{Participant, Donor, Challenge}
  alias SendGrid.{Mail, Email}

  @challenge_attachment_types [
    :new_challenges,
    :challenges_new_users,
    :challenges_milestones,
    :challenges_completed
  ]
  @attachment_types [:signups, :new_donors | @challenge_attachment_types]

  def send_digest_email(params) do
    result =
      params
      |> signups_digest_email()
      |> Mail.send()

    Map.put(params, :mailer_result, result)
  end

  def signups_digest_email(params) do
    email =
      Email.build()
      |> Email.put_from("admin@bravera.co", "Bravera")
      |> Email.put_subject("Daily Activity Digest")
      |> Email.put_text(text(params))
      |> Email.add_to("admin@bravera.co")

    Enum.reduce(@attachment_types, email, fn type, email ->
      add_csv_attachment(email, params, type)
    end)
  end

  defp text(%{
         signups: s,
         new_challenges: nc,
         challenges_new_users: cnu,
         challenges_milestones: cwm,
         challenges_completed: cc,
         new_donors: dn
       }) do
    "In the past 24h we've had #{length(s)} signups, #{length(dn)} new donors, #{length(nc)} new Challenges, " <>
      "out of which, #{length(cnu)} is by new users. " <>
      "We've also had #{length(cwm)} challenges with completed milestones out of which #{length(cc)} reached completion. " <>
      "Attached are the relevant CSV files for the new entries"
  end

  defp add_csv_attachment(email, params, type) do
    list = Map.get(params, type)

    if length(list) > 0 do
      Email.add_attachment(email, %{
        content: to_csv(list, type),
        filename: "#{type}_#{yesterday()}.csv"
      })
    else
      email
    end
  end

  defp to_csv(list, type) do
    list
    |> csv_encode(type)
    # forcing the stream to be processed
    |> Enum.take(length(list) + 1)
    |> Enum.join("")
    |> Base.encode64()
  end

  defp csv_encode(users, :signups) do
    users
    |> Enum.map(&Participant.serialize/1)
    |> CSV.encode(headers: Participant.fields())
  end

  defp csv_encode(donors, :new_donors) do
    donors
    |> Enum.map(&Donor.serialize/1)
    |> CSV.encode(headers: Donor.fields())
  end

  defp csv_encode(challenges, type) when type in @challenge_attachment_types do
    challenges
    |> Enum.map(&Challenge.serialize/1)
    |> CSV.encode(headers: Challenge.fields())
  end

  defp csv_encode(_, _) do
    []
  end

  defp yesterday, do: Timex.shift(Timex.today(), days: -1)
end
