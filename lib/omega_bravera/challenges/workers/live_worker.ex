defmodule OmegaBravera.Challenges.LiveWorker do
  require Logger

  alias OmegaBravera.{Repo, Challenges, Challenges.Notifier}
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  def start() do
    Challenges.get_live_ngo_chals()
    |> Enum.map(fn challenge ->
      challenge = challenge |> Repo.preload([:ngo, :user])

      case Challenges.update_ngo_chal(challenge, challenge.user, %{status: "active"}) do
        {:ok, _} ->
          Logger.info("LiveChallenges worker: activated challenge: #{inspect(challenge.slug)}")

          Notifier.send_challenge_activated_email(
            challenge,
            Routes.ngo_ngo_chal_path(Endpoint, :show, challenge.ngo.slug, challenge.slug)
          )

        {:error, reason} ->
          Logger.error(
            "LiveChallenges worker: failed to activate challenge. Reason: #{inspect(reason)}"
          )
      end
    end)
  end
end
