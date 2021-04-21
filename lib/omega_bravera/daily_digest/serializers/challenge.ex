defmodule OmegaBravera.DailyDigest.Serializers.Challenge do
  alias OmegaBravera.{Repo, Challenges.NGOChal, Accounts.User}

  def fields, do: [:challenger]

  def serialize(%NGOChal{} = ch) do
    challenge = Repo.preload(ch, [:user])
    %{challenger: User.full_name(challenge.user)}
  end
end
