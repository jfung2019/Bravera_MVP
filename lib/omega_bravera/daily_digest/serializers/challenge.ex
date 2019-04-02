defmodule OmegaBravera.DailyDigest.Serializers.Challenge do
  alias OmegaBravera.{Repo, Challenges.NGOChal, Accounts.User}
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  def fields, do: [:challenger, :url]

  def serialize(%NGOChal{} = ch) do
    challenge = Repo.preload(ch, [:user, :ngo])
    %{challenger: User.full_name(challenge.user), url: challenge_url(challenge)}
  end

  defp challenge_url(challenge) do
    Routes.ngo_ngo_chal_url(Endpoint, :show, challenge.ngo.slug, challenge.slug)
  end
end
