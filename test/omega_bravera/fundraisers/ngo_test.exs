defmodule OmegaBravera.NgoTest do
  use OmegaBravera.DataCase
  use Timex

  import OmegaBravera.Factory

  alias OmegaBravera.Fundraisers.NGO

  describe "ngo custom validators" do
    @create_attrs %{
      name: "some ngo",
      slug: "some-ngo",
      pre_registration_start_date: Timex.now("Asia/Hong_Kong"),
      launch_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 10),
      minimum_donation: 500,
      open_registration: true,
      url: "https://test.com",
      image: "/image.png",
      logo: "/logo.png"
    }

    test "changeset/2 passes if correct params are given" do
      ngo = NGO.changeset(%NGO{}, @create_attrs)
      assert ngo.valid?
    end

    test "changeset/2 fails if pre-registration-start-date is equal to or greater than launch date" do
      ngo =
        NGO.changeset(
          %NGO{},
          %{
            @create_attrs
            | pre_registration_start_date:
                Timex.shift(@create_attrs.pre_registration_start_date, days: 11),
              open_registration: false
          }
        )

      refute ngo.valid?

      ngo =
        NGO.changeset(
          %NGO{},
          %{
            @create_attrs
            | pre_registration_start_date: @create_attrs.launch_date,
              open_registration: false
          }
        )

      refute ngo.valid?
    end

    test "changeset/2 fails if open_registeration is true but registration dates are nil" do
      ngo =
        NGO.changeset(
          %NGO{},
          %{
            @create_attrs
            | pre_registration_start_date: nil,
              launch_date: nil,
              open_registration: false
          }
        )

      refute ngo.valid?
    end

    test "changeset/2 is valid if open_registeration is true and registration dates are nil" do
      ngo =
        NGO.changeset(
          %NGO{},
          %{
            @create_attrs
            | pre_registration_start_date: nil,
              launch_date: nil,
              open_registration: true
          }
        )

      assert ngo.valid?
    end

    test "changeset/2 is valid if open_registeration is true and launch date is greater than today." do
      ngo =
        NGO.changeset(
          %NGO{},
          %{
            @create_attrs
            | launch_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: -10),
              open_registration: false
          }
        )

      refute ngo.valid?
    end

    test "update_changeset/2 fails if admin edits pre_registeration_start because it has been reached." do
      ngo = build(:ngo)

      updated_ngo =
        NGO.update_changeset(
          ngo,
          %{
            pre_registration_start_date: Timex.shift(ngo.pre_registration_start_date, days: 2),
            open_registration: false
          }
        )

      refute updated_ngo.valid?
    end

    test "update_changeset/2 is vaild when pre_registration_start_date is less than now." do
      ngo = build(:ngo, %{pre_registration_start_date: Timex.now("Asia/Hong_Kong")})

      updated_ngo =
        NGO.update_changeset(
          ngo,
          %{
            pre_registration_start_date: Timex.shift(ngo.pre_registration_start_date, days: -2),
            open_registration: false
          }
        )

      assert updated_ngo.valid?
    end

    test "update_changeset/2 fails if admin tries to edit pre_registration_start_date or launch_date if there're active challenges." do
      ngo = build(:ngo, %{active_challenges: 1})

      updated_ngo = NGO.update_changeset(ngo, %{open_registration: false})

      refute updated_ngo.valid?
    end
  end
end
