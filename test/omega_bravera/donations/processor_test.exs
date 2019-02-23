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
               charge_id: "ch_1Ds8ugEXtHU8QBy8i6WT5pk6",
               charged_amount: Decimal.from_float(10.0),
               charged_description: "Donation to Save the children via Bravera.co",
               charged_status: "succeeded",
               last_digits: "4242"
             }

      assert Timex.equal?(result.charged_at, DateTime.from_unix!(1_547_385_726))
    end
  end

  test "charge_donation/1 charges km challenge pledge sucessfully and makes user pay for fees" do
    donor = insert(:user, %{email: "sheriefalaa.w@gmail.com"})
    ngo = insert(:ngo, %{slug: "stc", name: "Save the children"})
    challenge = insert(:ngo_challenge, %{ngo: ngo, type: "PER_KM", activity_type: "Walk"})
    insert(:activity, %{challenge: challenge, distance: Decimal.new(10)})

    donation_attrs = %{
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      user: donor,
      ngo: ngo,
      ngo_chal: challenge,
      donor_pays_fees: true
    }

    donation = insert(:donation, donation_attrs)

    use_cassette "charge_km_donation" do
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
               charge_id: "ch_1Ds9ADEXtHU8QBy8S5PkhhSG",
               charged_amount: Decimal.from_float(111.75),
               charged_description: "Donation to Save the children via Bravera.co",
               charged_status: "succeeded",
               last_digits: "4242"
             }

      assert Timex.equal?(result.charged_at, DateTime.from_unix!(1_547_386_689))
    end
  end

  test "charge_donation/1 charges km challenge pledge sucessfully and distance_covered cannot exceed distance_target" do
    donor = insert(:user, %{email: "sheriefalaa.w@gmail.com"})
    ngo = insert(:ngo, %{slug: "stc", name: "Save the children"})

    challenge =
      insert(:ngo_challenge, %{
        ngo: ngo,
        type: "PER_KM",
        activity_type: "Walk",
        distance_target: 50
      })

    insert(:activity, %{challenge: challenge, distance: Decimal.new(60)})

    donation_attrs = %{
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      user: donor,
      ngo: ngo,
      ngo_chal: challenge,
      donor_pays_fees: false,
      amount: Decimal.new(10)
    }

    donation = insert(:donation, donation_attrs)

    use_cassette "charge_km_donation_cannot_exceed_distance_target" do
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
               charge_id: "ch_1DwSC6EXtHU8QBy8f95J7Zsn",
               charged_amount: Decimal.from_float(500.0),
               charged_description: "Donation to Save the children via Bravera.co",
               charged_status: "succeeded",
               last_digits: "4242"
             }

      assert Timex.equal?(result.charged_at, DateTime.from_unix!(1_548_413_154))
    end
  end

  test "charge_donation/1 switches status to failed when donation fails to be charged" do
    donor = insert(:user, %{email: "sheriefalaa.w@gmail.com"})

    ngo = insert(:ngo, %{slug: "stc", name: "Save the children"})

    challenge = insert(:ngo_challenge, %{ngo: ngo})

    donation_attrs = %{
      str_cus_id: "cus_DaUL9L27e843XN",
      str_src: "src_1D9JN4EXtHU8QBy8JErKq6fH",
      user: donor,
      ngo: ngo,
      ngo_chal: challenge,
      amount: Decimal.new(0)
    }

    donation = insert(:donation, donation_attrs)

    use_cassette "charge_donation_fails" do
      {:error, :unknown_error} = Processor.charge_donation(donation)
      result = Repo.get(Donation, donation.id)

      assert result.status == "failed"
    end
  end

  # TODO: write a test for a non-hkd challenge and see if the exchange rate comes back other than nil inside balance_transaction
end
