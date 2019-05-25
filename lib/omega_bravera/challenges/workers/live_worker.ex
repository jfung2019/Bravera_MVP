defmodule OmegaBravera.Challenges.LiveWorker do
  require Logger

  alias OmegaBravera.{Repo, Challenges}
  alias OmegaBravera.{Offers}

  def start() do
    Challenges.get_live_ngo_chals()
    |> Enum.map(fn challenge ->
      challenge = challenge |> Repo.preload([:ngo, :user])

      case Challenges.update_ngo_chal(challenge, challenge.user, %{status: "active"}) do
        {:ok, _} ->
          Logger.info("LiveChallenges worker: activated challenge: #{inspect(challenge.slug)}")

          Challenges.Notifier.send_challenge_activated_email(challenge)

        {:error, reason} ->
          Logger.error(
            "LiveChallenges worker: failed to activate challenge. Reason: #{inspect(reason)}"
          )
      end
    end)

    Offers.get_live_offer_challenges()
    |> Enum.map(fn challenge ->
      challenge = Repo.preload(challenge, [:offer, :user])

      case Offers.update_offer_challenge(challenge, %{status: "active"}) do
        {:ok, _} ->
          Logger.info(
            "LiveChallenges worker: activated offer challenge: #{inspect(challenge.slug)}"
          )

          Offers.Notifier.send_challenge_activated_email(challenge)

        {:error, reason} ->
          Logger.error(
            "LiveChallenges worker: failed to activate offer challenge. Reason: #{inspect(reason)}"
          )
      end
    end)
  end
end
