defmodule OmegaBravera.Donations.PledgesTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges.NGOChal, Donations.Pledges, Repo}

  setup do
    donor = insert(:user)
    user = insert(:user, %{email: "simon.garciar@gmail.com", firstname: "Simon", lastname: "Garcia"})

    donation_params = %{
      "currency" => "HKD",
      "donor_id" => donor.id,
      "email" => "test@test.com",
      "first_name" => "Test",
      "last_name" => "User",
      "milestone_1" => "25",
      "milestone_3" => "30",
      "milestone_2" => "30",
      "milestone_4" => "25",
      "str_src" => "src_123JABD8554"
    }

    {:ok, [user: user, donor: donor, donation_params: donation_params]}
  end

  test "create/3 creates the pledges and updates the challenge", %{user: user, donation_params: params} do
    stripe_customer = %{"id" => "cus_123456"}
    challenge = insert(:ngo_challenge, %{user: user})

    {:ok, pledges} = Pledges.create(challenge, stripe_customer, params)
    challenge = Repo.get(NGOChal, challenge.id)

    assert length(pledges) == 4
    assert challenge.total_pledged == Decimal.new(110)
    assert challenge.self_donated == false
  end

  test "create/3 returns and error tuple when the stripe customer creation fails", %{user: user, donation_params: params} do
    stripe_customer = %{"error" => %{"code" => "card_declined"}}
    challenge = insert(:ngo_challenge, %{user: user})

    assert Pledges.create(challenge, stripe_customer, params) == {:error, :pledge_creation_error}
  end

  test "create/3 sets the challenge to self donated once the challenge creator donates", %{user: user, donation_params: p} do
    params = Map.merge(p, %{"donor_id" => user.id, "email" => user.email, "first_name" => user.firstname, "last_name" => user.lastname})
    stripe_customer = %{"id" => "cus_123456"}
    challenge = insert(:ngo_challenge, %{user: user})

    {:ok, _} = Pledges.create(challenge, stripe_customer, params)
    challenge = Repo.get(NGOChal, challenge.id)

    assert challenge.self_donated == true
  end

  test "create/3 doesn't reset the self donate column once the challenge creator has already donated", %{user: user, donation_params: params} do
    stripe_customer = %{"id" => "cus_123456"}
    challenge = insert(:ngo_challenge, %{user: user, self_donated: true})

    {:ok, _} = Pledges.create(challenge, stripe_customer, params)
    challenge = Repo.get(NGOChal, challenge.id)

    assert challenge.self_donated == true
  end
end

