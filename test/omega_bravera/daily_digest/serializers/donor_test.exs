defmodule OmegaBravera.DailyDigest.Serializers.DonorTest do
  use OmegaBravera.DataCase, async: true
  import OmegaBravera.Factory
  alias OmegaBravera.DailyDigest.Serializers.Donor

  test "serialize/1 returns a map with the fields for the csv" do
    donor =
      insert(:user, %{firstname: "Simon", lastname: "Garcia", email: "simon.garciar@gmail.com"})

    first_challenge = insert(:ngo_challenge, %{user: donor, slug: "test-123"})
    second_challenge = insert(:ngo_challenge, %{user: donor, slug: "test-987"})

    insert(:donation, %{ngo_chal: first_challenge, ngo: first_challenge.ngo, user: donor})

    insert(:donation, %{
      ngo_chal: first_challenge,
      ngo: first_challenge.ngo,
      user: donor,
      milestone: 2
    })

    insert(:donation, %{
      ngo_chal: first_challenge,
      ngo: first_challenge.ngo,
      user: donor,
      milestone: 3
    })

    insert(:donation, %{
      ngo_chal: first_challenge,
      ngo: first_challenge.ngo,
      user: donor,
      milestone: 4
    })

    insert(:donation, %{ngo_chal: second_challenge, ngo: second_challenge.ngo, user: donor})

    insert(:donation, %{
      ngo_chal: second_challenge,
      ngo: second_challenge.ngo,
      user: donor,
      milestone: 2
    })

    insert(:donation, %{
      ngo_chal: second_challenge,
      ngo: second_challenge.ngo,
      user: donor,
      milestone: 3
    })

    insert(:donation, %{
      ngo_chal: second_challenge,
      ngo: second_challenge.ngo,
      user: donor,
      milestone: 4
    })

    result = Donor.serialize(donor)

    assert result == %{
             firstname: "Simon",
             lastname: "Garcia",
             email: "simon.garciar@gmail.com",
             pledged_amount: "$1200 HKD"
           }
  end
end
