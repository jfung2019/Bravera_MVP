defmodule OmegaBravera.Money.DonationTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Money.Donation}
 
  test "charged_changeset/2 sets the charged status fields based on the Stripe's API response" do
    donation = insert(:donation)
    stripe_response = %{
      "source" => %{
        "amount" => nil,
        "card" => %{
          "brand" => "Visa",
          "last4" => "4242"
        }
      },
      "created" => 1536701169,
      "amount" => 15000,
      "id" => "ch_1D9JN7EXtHU8QBy8AYC2qXct",
      "status" => "succeeded",
      "description" => "Donation to Save the children via Bravera.co"
    }

    assert donation.status == "pending"

    changeset = Donation.charge_changeset(donation, stripe_response)

    assert changeset.changes == %{
      charge_id: "ch_1D9JN7EXtHU8QBy8AYC2qXct",
      last_digits: "4242",
      card_brand: "Visa",
      charged_description: "Donation to Save the children via Bravera.co",
      charged_status: "succeeded",
      charged_amount: Decimal.new(150.0),
      charged_at: DateTime.from_unix!(1536701169),
      status: "charged"
    }
  end
end
