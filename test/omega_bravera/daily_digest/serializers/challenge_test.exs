defmodule OmegaBravera.DailyDigest.Serializers.ChallengeTest do
  use OmegaBravera.DataCase, async: true
  import OmegaBravera.Factory

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

  alias OmegaBravera.{DailyDigest.Serializers.Challenge, Accounts.User}

  test "serialize/1 returns a map with the fields for the csv" do
    challenge = insert(:ngo_challenge)
    assert Challenge.serialize(challenge) == %{challenger: User.full_name(challenge.user)}
  end
end
