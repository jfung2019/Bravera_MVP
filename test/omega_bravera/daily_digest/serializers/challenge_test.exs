defmodule OmegaBravera.DailyDigest.Serializers.ChallengeTest do
  use OmegaBravera.DataCase, async: true
  import OmegaBravera.Factory

  alias OmegaBravera.DailyDigest.Serializers.Challenge

  test "serialize/1 returns a map with the fields for the csv" do
    challenge = insert(:ngo_challenge)

    assert Challenge.serialize(challenge) == %{
             challenger: "#{challenge.user.firstname} #{challenge.user.lastname}",
             url: "https://bravera.co/#{challenge.ngo.slug}/#{challenge.slug}"
           }
  end
end
