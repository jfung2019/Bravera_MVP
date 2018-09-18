defmodule OmegaBravera.DailyDigest.Serializers.Challenge do
  alias OmegaBravera.{Repo, Challenges.NGOChal, Accounts.User}

  def fields, do: [:challenger, :url]

  def serialize(%NGOChal{} = ch) do
    challenge = Repo.preload(ch, [:user, :ngo])
    %{challenger: User.full_name(challenge.user), url: challenge_url(challenge)}
  end

  defp challenge_url(challenge) do
    "#{Application.get_env(:omega_bravera, :app_base_url)}/#{challenge.ngo.slug}/#{challenge.slug}"
  end
end
