defmodule OmegaBravera.Donations.ProcessorTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{Money.Donation, Donations.Processor}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
  end

  test "charge_donation/1 charges the donation and updates the schema successfully" do
    donor = insert(:user, %{email: "simon.garciar@gmail.com"})

    ngo = insert(:ngo, %{slug: "stc", name: "Save the children"})

    challenge = insert(:ngo_challenge, %{ngo: ngo})

    donation_attrs = %{
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      user: donor,
      ngo: ngo,
      ngo_chal: challenge
    }

    donation = insert(:donation, donation_attrs)

    use_cassette "charge_donation" do
      {:ok, %Donation{status: "charged"} = donation} = Processor.charge_donation(donation)
      result = Repo.get(Donation, donation.id)

      fields = [
        :charge_id,
        :last_digits,
        :card_brand,
        :charged_description,
        :charged_status,
        :charged_amount
      ]

      charged_fields = Map.take(result, fields)

      assert charged_fields == %{
               card_brand: "Visa",
               charge_id: "ch_1DlGQgEXtHU8QBy8l5ksSULe",
               charged_amount: Decimal.new(13.29),
               charged_description: "Donation to Save the children via Bravera.co",
               charged_status: "succeeded",
               last_digits: "4242"
             }

      assert Timex.equal?(result.charged_at, DateTime.from_unix!(1_545_746_322))
    end
  end

  # TODO: write a test for a non-hkd challenge and see if the exchange rate comes back other than nil inside balance_transaction
end
