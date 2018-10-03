defmodule OmegaBravera.DailyDigest.Serializers.ParticipantTest do
  use OmegaBravera.DataCase, async: true
  import OmegaBravera.Factory

  alias OmegaBravera.DailyDigest.Serializers.Participant

  test "serialize/1 returns a map with the fields for the csv" do
    user = insert(:user, %{additional_info: %{"location" => "//", "sex" => nil}})
    strava = insert(:strava, %{user: user})

    assert Participant.serialize(user) == %{
             firstname: user.firstname,
             lastname: user.lastname,
             email: user.email,
             strava_id:
               "#{strava.athlete_id} (https://www.strava.com/athletes/#{strava.athlete_id})",
             sex: "Not specified",
             location: "Not specified"
           }
  end

  test "serialize/1 returns the correct sex for the user" do
    male = insert(:user, %{additional_info: %{"sex" => "M"}})
    insert(:strava, %{user: male})

    female = insert(:user, %{additional_info: %{"sex" => "F"}})
    insert(:strava, %{user: female})

    non_specified = insert(:user)
    insert(:strava, %{user: non_specified})

    assert Participant.serialize(male)[:sex] == "M"
    assert Participant.serialize(female)[:sex] == "F"
    assert Participant.serialize(non_specified)[:sex] == "Not specified"
  end

  test "serialize/1 returns the correct location for the user" do
    user = insert(:user, %{additional_info: %{"location" => "Barcelona/Barcelona/Spain"}})
    insert(:strava, %{user: user})

    non_specified = insert(:user, %{additional_info: %{"location" => "//"}})
    insert(:strava, %{user: non_specified})

    assert Participant.serialize(user)[:location] == "Barcelona/Barcelona/Spain"
    assert Participant.serialize(non_specified)[:location] == "Not specified"
  end
end
