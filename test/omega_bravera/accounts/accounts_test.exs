defmodule OmegaBravera.AccountsTest do
  use OmegaBravera.DataCase, async: false

  import OmegaBravera.Factory
  alias OmegaBravera.Accounts.{AdminUser, User, Credential}

  alias OmegaBravera.{
    Accounts,
    Fixtures,
    Repo,
    Trackers.Strava
  }

  describe "users" do
    test "donors_for_challenge/1 returns all donors for a challenge" do
      user = insert(:user)
      ngo = insert(:ngo, %{slug: "swcc-1"})
      challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})

      # 2 famous runners
      matthew_wells =
        insert(:donor, %{firstname: "Matthew", lastname: "Wells", email: "matthew.wells@test.com"})

      carlos_cordero =
        insert(:donor, %{
          firstname: "Carlos",
          lastname: "Cordero",
          email: "carlos.cordero@test.com"
        })

      insert(:donation, %{ngo_chal: challenge, ngo: ngo, donor: carlos_cordero})
      insert(:donation, %{ngo_chal: challenge, ngo: ngo, donor: matthew_wells})

      donors =
        challenge
        |> Accounts.donors_for_challenge()

      assert donors == [matthew_wells, carlos_cordero]
    end

    test "insert_or_update_strava_user/1 creates both user and strava tracker" do
      attrs = %{
        athlete_id: 33_762_738,
        email: "simon.garciar@gmail.com",
        firstname: "Rafael",
        lastname: "Garcia",
        token: "87318aaded9cdeb99a1a3c20c6af26ccf059de30",
        refresh_token: "abcd129031092asd}",
        token_expires_at: Timex.shift(Timex.now(), hours: 5),
        additional_info: %{sex: "M", location: "Spain/Barcelona/Barcelona"}
      }

      {:ok, %{strava: %Strava{} = strava, user: %Accounts.User{} = user}} =
        Accounts.insert_or_update_strava_user(attrs)

      assert user.email == "simon.garciar@gmail.com"
      assert strava.athlete_id == 33_762_738
    end

    test "insert_or_update_strava_user/1 updates both user and strava tracker" do
      user_attrs = %{firstname: "Rafael", lastname: "Garcia", email: "simon.garciar@gmail.com"}
      user = insert(:user, user_attrs)

      strava =
        insert(
          :strava,
          Map.merge(user_attrs, %{
            token: "abcdef",
            user: user,
            refresh_token: "abcd129031092asd}",
            token_expires_at: Timex.shift(Timex.now(), hours: 5)
          })
        )

      attrs = %{
        athlete_id: strava.athlete_id,
        email: "simon.garciar@gmail.com",
        firstname: "Rafael",
        lastname: "Garcia",
        token: "87318aaded9cdeb99a1a3c20c6af26ccf059de30",
        additional_info: %{sex: "M", location: "Spain/Barcelona/Barcelona"},
        strava_profile_picture: "some-profile-picture.png",
        refresh_token: "abcd129031092asd}",
        token_expires_at: Timex.shift(Timex.now(), hours: 5)
      }

      {:ok, user} = Accounts.insert_or_update_strava_user(attrs)

      user = Repo.preload(user, [:strava])

      assert user.additional_info[:sex] == "M"
      assert user.additional_info[:location] == "Spain/Barcelona/Barcelona"
      assert user.strava.athlete_id == attrs.athlete_id
      assert user.strava.token == "87318aaded9cdeb99a1a3c20c6af26ccf059de30"
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{email_activation_token: token} = user} =
               Accounts.create_user(%{
                 email: "test@test.com",
                 firstname: "some firstname",
                 lastname: "some lastname",
                 location_id: 1
               })

      assert user.email == "test@test.com"
      assert user.firstname == "some firstname"
      assert user.lastname == "some lastname"
      assert user.username == "#{user.firstname} #{user.lastname}"
      assert Regex.match?(~r/^\d{6}$/, token)
    end

    test "cannot enter email with space at the beginning, end or middle" do
      assert {:error, _} =
               Accounts.create_user(%{
                 email: " test@test.com",
                 firstname: "some firstname",
                 lastname: "some lastname",
                 location_id: 1
               })

      assert {:error, _} =
               Accounts.create_user(%{
                 email: "test@test.com ",
                 firstname: "some firstname",
                 lastname: "some lastname",
                 location_id: 1
               })

      assert {:error, _} =
               Accounts.create_user(%{
                 email: "te st@test.com",
                 firstname: "some firstname",
                 lastname: "some lastname",
                 location_id: 1
               })
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{email: nil, firstname: nil, lastname: nil})
    end

    test "create credential user will enqueue 2 jobs to check and email if need to" do
      assert {:ok, %{id: _user_id}} =
               Accounts.create_credential_user(%{
                 email: "test@test.com",
                 firstname: "some firstname",
                 lastname: "some lastname",
                 location_id: 1,
                 accept_terms: true,
                 credential: %{password: "Test@test", password_confirmation: "Test@test"}
               })

      assert_enqueued(worker: Accounts.Jobs.NoActivityAfterSignup, queue: :email)
      assert_enqueued(worker: Accounts.Jobs.OneWeekNoActivityAfterSignup, queue: :email)
    end
  end

  describe "user created" do
    setup do: {:ok, user: Fixtures.user_fixture()}

    test "list_users/0 returns all users", %{user: user} do
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id", %{user: user} do
      assert Accounts.get_user!(user.id) == user
    end

    test "update_user/2 with valid data updates the user", %{user: user} do
      assert {:ok, user} =
               Accounts.update_user(user, %{
                 email: "updated_test@test.com",
                 firstname: "some updated firstname",
                 lastname: "some updated lastname"
               })

      assert %User{} = user
      assert user.email == "updated_test@test.com"
      assert user.firstname == "some updated firstname"
      assert user.lastname == "some updated lastname"
    end

    test "update_user/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user(user, %{email: nil, firstname: nil, lastname: nil})

      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user", %{user: user} do
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset", %{user: user} do
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "can get preloaded offer challenges that are active or haven't been redeemed", %{
      user: user
    } do
      vendor = insert(:vendor)
      offer = insert(:offer, %{vendor: nil, vendor_id: vendor.id})
      offer_reward = insert(:offer_reward, %{offer: nil, offer_id: offer.id})

      %{id: completed_id} =
        completed_challenge =
        insert(:offer_challenge, %{
          offer_id: offer.id,
          offer: nil,
          user: user,
          has_team: false,
          status: "complete",
          slug: "complete"
        })

      redeem_params = %{
        status: "redeemed",
        offer: offer,
        vendor: vendor,
        offer_challenge: nil,
        user: user,
        offer_reward: offer_reward
      }

      insert(:offer_redeem_with_args, %{redeem_params | offer_challenge: completed_challenge})

      %{id: completed_not_redeemed_id} =
        completed_not_redeemed_challenge =
        insert(:offer_challenge, %{
          offer_id: offer.id,
          offer: nil,
          user: user,
          has_team: false,
          status: "complete",
          slug: "complete_no_redeem"
        })

      insert(:offer_redeem_with_args, %{
        redeem_params
        | offer_challenge: completed_not_redeemed_challenge,
          status: "pending"
      })

      %{id: pre_reg_id} =
        insert(:offer_challenge, %{
          offer_id: offer.id,
          offer: nil,
          user: user,
          has_team: false,
          status: "pre_registration",
          slug: "pre"
        })

      %{id: active_id} =
        insert(:offer_challenge, %{
          offer: offer,
          user: user,
          has_team: false,
          status: "active",
          slug: "active"
        })

      %{offer_challenges: chals} = Accounts.preload_active_offer_challenges(user)
      chal_ids = Enum.map(chals, fn %{id: id} -> id end)
      assert active_id in chal_ids
      assert pre_reg_id in chal_ids
      assert completed_not_redeemed_id in chal_ids
      refute completed_id in chal_ids
    end

    test "verifying a users email will enqueue a job to send an email 3 days later", %{user: user} do
      assert {:ok, %{email_verified: false, email_activation_token: token} = user} =
               Accounts.update_user(user, %{email_verified: false})

      assert token != nil

      assert {:ok, %{email_verified: true, email_activation_token: nil}} =
               Accounts.activate_user_email(user)

      assert_enqueued(worker: Accounts.Jobs.AfterEmailVerify, queue: :email)
    end

    test "gdpr delete user", %{user: %{id: user_id}} do
      {:ok, _setting} =
        Accounts.create_setting(%{date_of_birth: Timex.now(), gender: "Other", user_id: user_id})

      assert {:ok,
              %{
                delete_user: %{
                  firstname: nil,
                  lastname: nil,
                  username: "deleted",
                  email: nil,
                  location_id: nil
                },
                delete_user_setting: {1, nil}
              }} = Accounts.gdpr_delete_user(user_id)
    end
  end

  describe "settings" do
    alias OmegaBravera.Accounts.Setting

    @valid_attrs %{
      location: "UK",
      weight_whole: 35,
      weight_fraction: 0.5,
      date_of_birth: "1940-07-14",
      gender: "Female"
    }
    @update_attrs %{
      location: "US",
      weight: 30.9,
      date_of_birth: "1980-07-14",
      gender: "Male"
    }
    @invalid_attrs %{
      location: nil,
      weight: nil,
      date_of_birth: nil,
      gender: nil,
      user_id: nil
    }

    def setting_fixture(attrs \\ %{}) do
      user = insert(:user)

      {:ok, setting} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:user_id, user.id)
        |> Accounts.create_setting()

      setting
      |> Map.put(:weight_whole, 0)
      |> Map.put(:weight_fraction, 0.0)
    end

    test "list_settings/0 returns all settings" do
      setting = setting_fixture()
      assert Accounts.list_settings() == [setting]
    end

    test "get_setting!/1 returns the setting with given id" do
      setting = setting_fixture()
      assert Accounts.get_setting!(setting.id) == setting
    end

    test "create_setting/1 with valid data creates a setting" do
      user = insert(:user)
      valid_attrs = Map.put(@valid_attrs, :user_id, user.id)
      assert {:ok, %Setting{} = setting} = Accounts.create_setting(valid_attrs)
      assert setting.location == "UK"
      assert setting.weight == Decimal.from_float(35.5)
      assert setting.date_of_birth == ~D[1940-07-14]
      assert setting.gender == "Female"
      assert setting.user_id == user.id
    end

    test "update_setting/2 with valid data updates the setting" do
      setting = setting_fixture()
      update_attrs = Map.put(@update_attrs, :user_id, setting.user_id)
      assert {:ok, setting} = Accounts.update_setting(setting, update_attrs)
      assert %Setting{} = setting
      assert setting.gender == "Male"
      assert setting.date_of_birth == ~D[1980-07-14]
    end

    test "delete_setting/1 deletes the setting" do
      setting = setting_fixture()
      assert {:ok, %Setting{}} = Accounts.delete_setting(setting)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_setting!(setting.id) end
    end

    test "change_setting/1 returns a setting changeset" do
      setting = setting_fixture()
      assert %Ecto.Changeset{} = Accounts.change_setting(setting)
    end
  end

  describe "admin_users" do
    test "create_admin_user/1 with valid data creates a admin_user" do
      assert {:ok, %AdminUser{} = admin_user} =
               Accounts.create_admin_user(%{email: "some@email.com", password: "Pass@1234"})

      assert admin_user.email == "some@email.com"
    end

    test "create_admin_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_admin_user(%{email: nil, password_hash: nil})
    end
  end

  describe "admin_user created" do
    setup do: {:ok, admin_user: Fixtures.admin_user_fixture()}

    test "list_admin_users/0 returns all admin_users", %{admin_user: admin_user} do
      admin_user = %{admin_user | password: nil}
      assert Accounts.list_admin_users() == [admin_user]
    end

    test "get_admin_user!/1 returns the admin_user with given id", %{admin_user: admin_user} do
      admin_user = %{admin_user | password: nil}
      assert Accounts.get_admin_user!(admin_user.id) == admin_user
    end

    test "update_admin_user/2 with valid data updates the admin_user", %{admin_user: admin_user} do
      assert {:ok, admin_user} =
               Accounts.update_admin_user(admin_user, %{
                 email: "some.updated@email.com",
                 password_hash: "nopass1234"
               })

      assert %AdminUser{} = admin_user
      assert admin_user.email == "some.updated@email.com"
    end

    test "update_admin_user/2 with invalid data returns error changeset", %{
      admin_user: admin_user
    } do
      admin_user = %{admin_user | password: nil}

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_admin_user(admin_user, %{email: nil, password_hash: nil})

      assert admin_user == Accounts.get_admin_user!(admin_user.id)
    end

    test "delete_admin_user/1 deletes the admin_user", %{admin_user: admin_user} do
      assert {:ok, %AdminUser{}} = Accounts.delete_admin_user(admin_user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_admin_user!(admin_user.id) end
    end

    test "change_admin_user/1 returns a admin_user changeset", %{admin_user: admin_user} do
      assert %Ecto.Changeset{} = Accounts.change_admin_user(admin_user)
    end
  end

  describe "authenticat_admin_user_by_email_and_pass/2" do
    @email "user@localhost.com"
    @pass "Test@123"

    alias OmegaBravera.Accounts.AdminUser

    setup do
      {:ok, user: Fixtures.admin_user_fixture(%{email: @email, password: @pass})}
    end

    test "returns user with correct password", %{user: %AdminUser{id: id}} do
      assert {:ok, %AdminUser{id: ^id}} =
               Accounts.authenticate_admin_user_by_email_and_pass(@email, @pass)
    end

    test "immune to mixed cased emails", %{user: %AdminUser{id: id}} do
      assert {:ok, %AdminUser{id: ^id}} =
               Accounts.authenticate_admin_user_by_email_and_pass(
                 String.capitalize(@email),
                 @pass
               )
    end

    test "returns unauthorized error with invalid password" do
      assert {:error, :unauthorized} =
               Accounts.authenticate_admin_user_by_email_and_pass(@email, "badpass")
    end

    test "returns not found error with no matching user for email" do
      assert {:error, :not_found} =
               Accounts.authenticate_admin_user_by_email_and_pass("bademail@localhost", @pass)
    end
  end

  describe "email_password_auth/2" do
    @password "Dev@1234"

    def credential_fixture() do
      user = insert(:user)

      credential_attrs = %{
        password: @password,
        password_confirmation: @password
      }

      {:ok, credential} =
        Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
        |> Repo.insert()

      credential |> Repo.preload(:user)
    end

    test "when correct credentials are given, {:ok, user} is returned" do
      credential = credential_fixture()
      {:ok, user} = Accounts.email_password_auth(credential.user.email, @password)

      assert user.id == credential.user.id
    end

    test "when invalid credentials are provided, {:error, reason} is returned" do
      credential = credential_fixture()

      assert {:error, :invalid_password} =
               Accounts.email_password_auth(credential.user.email, "bad password")
    end
  end

  describe "donors" do
    alias OmegaBravera.Accounts.Donor

    @valid_attrs %{email: "some email", firstname: "some firstname", lastname: "some lastname"}
    @update_attrs %{
      email: "some updated email",
      firstname: "some updated firstname",
      lastname: "some updated lastname"
    }
    @invalid_attrs %{email: nil, firstname: nil, lastname: nil}

    def donor_fixture(attrs \\ %{}) do
      {:ok, donor} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_donor()

      donor
    end

    test "list_donors/0 returns all donors" do
      donor = donor_fixture()
      assert Accounts.list_donors() == [donor]
    end

    test "get_donor!/1 returns the donor with given id" do
      donor = donor_fixture()
      assert Accounts.get_donor!(donor.id) == donor
    end

    test "create_donor/1 with valid data creates a donor" do
      assert {:ok, %Donor{} = donor} = Accounts.create_donor(@valid_attrs)
      assert donor.email == "some email"
      assert donor.firstname == "some firstname"
      assert donor.lastname == "some lastname"
    end

    test "create_donor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_donor(@invalid_attrs)
    end

    test "update_donor/2 with valid data updates the donor" do
      donor = donor_fixture()
      assert {:ok, %Donor{} = donor} = Accounts.update_donor(donor, @update_attrs)
      assert donor.email == "some updated email"
      assert donor.firstname == "some updated firstname"
      assert donor.lastname == "some updated lastname"
    end

    test "update_donor/2 with invalid data returns error changeset" do
      donor = donor_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_donor(donor, @invalid_attrs)
      assert donor == Accounts.get_donor!(donor.id)
    end

    test "delete_donor/1 deletes the donor" do
      donor = donor_fixture()
      assert {:ok, %Donor{}} = Accounts.delete_donor(donor)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_donor!(donor.id) end
    end

    test "change_donor/1 returns a donor changeset" do
      donor = donor_fixture()
      assert %Ecto.Changeset{} = Accounts.change_donor(donor)
    end
  end

  describe "organization" do
    alias OmegaBravera.Accounts.Organization

    @valid_attrs %{
      name: "some name",
      business_type: "type",
      business_website: "https://www.bravera.fit/"
    }
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def organization_fixture(attrs \\ %{}) do
      {:ok, organization} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_organization()

      organization
    end

    test "list_organization/0 returns all organization" do
      organization = organization_fixture()
      assert Accounts.list_organization() == [organization]
    end

    test "get_organization!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Accounts.get_organization!(organization.id) == organization
    end

    test "create_organization/1 with valid data creates a organization" do
      assert {:ok, %Organization{} = organization} = Accounts.create_organization(@valid_attrs)
      assert organization.name == "some name"
    end

    test "create_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()

      assert {:ok, %Organization{} = organization} =
               Accounts.update_organization(organization, @update_attrs)

      assert organization.name == "some updated name"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_organization(organization, @invalid_attrs)

      assert organization == Accounts.get_organization!(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Accounts.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_organization!(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Accounts.change_organization(organization)
    end
  end

  describe "organization_members" do
    alias OmegaBravera.Accounts.OrganizationMember

    def organization_member_fixture(attrs \\ %{}) do
      {:ok, organization} =
        Accounts.create_organization(
          Map.merge(attrs, %{
            name: "name",
            business_type: "type",
            business_website: "https://www.bravera.fit/"
          })
        )

      location = Fixtures.location_fixture()

      {:ok, organization_member} =
        Accounts.create_organization_partner_user(%{
          organization_id: organization.id,
          partner_user: %{
            username: "name2",
            email: "iu@email.com",
            password: "Test@123456",
            password_confirmation: "Test@123456",
            first_name: "First Name",
            last_name: "Last Name",
            location_id: location.id,
            contact_number: "00000000"
          }
        })

      organization_member
    end

    test "list_organization_members/0 returns all organization_members" do
      %{id: member_id} = organization_member_fixture()
      assert [%{id: ^member_id}] = Accounts.list_organization_members()
    end

    test "get_organization_member!/1 returns the organization_member with given id" do
      organization_member = organization_member_fixture()

      assert Accounts.get_organization_member!(organization_member.id).id ==
               organization_member.id
    end

    test "create_organization_member/1 with valid data creates a organization_member" do
      location = Fixtures.location_fixture()

      assert {:ok, organization} =
               Accounts.create_organization(%{
                 name: "name",
                 business_type: "type",
                 business_website: "https://www.bravera.fit/"
               })

      assert {:ok, %OrganizationMember{partner_user: %{email_verified: true}}} =
               Accounts.create_organization_partner_user(%{
                 organization_id: organization.id,
                 partner_user: %{
                   username: "name2",
                   email: "iu@email.com",
                   first_name: "First Name",
                   last_name: "Last Name",
                   location_id: location.id,
                   contact_number: "00000000",
                   password: "Test@123456",
                   password_confirmation: "Test@123456"
                 }
               })
    end

    test "create_organization_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_organization_member(@invalid_attrs)
    end

    test "update_organization_member/2 with valid data updates the organization_member" do
      organization_member = organization_member_fixture()

      assert {:ok, %OrganizationMember{}} =
               Accounts.update_organization_member(organization_member, @update_attrs)
    end

    test "update_organization_member/2 with invalid data returns error changeset" do
      %{updated_at: updated_at} = organization_member = organization_member_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_organization_partner_user(organization_member, %{
                 partner_user: %{password: "123"}
               })

      assert %{updated_at: ^updated_at} =
               Accounts.get_organization_member!(organization_member.id)
    end

    test "delete_organization_member/1 deletes the organization_member" do
      organization_member = organization_member_fixture()

      assert {:ok, %OrganizationMember{}} =
               Accounts.delete_organization_member(organization_member)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_organization_member!(organization_member.id)
      end
    end

    test "change_organization_member/1 returns a organization_member changeset" do
      organization_member = organization_member_fixture()
      assert %Ecto.Changeset{} = Accounts.change_organization_member(organization_member)
    end
  end

  describe "friend chat messages" do
    setup do
      user = insert(:user)
      user2 = insert(:user, %{email: "user2@email.com"})
      user3 = insert(:user, %{email: "use3@email.com"})

      {:ok, friend} =
        Accounts.create_friend_request(%{receiver_id: user.id, requester_id: user2.id})

      {:ok, friend2} =
        Accounts.create_friend_request(%{receiver_id: user.id, requester_id: user3.id})

      Accounts.accept_friend_request(friend)
      Accounts.accept_friend_request(friend2)

      {:ok, user: user, user2: user2, user3: user3}
    end

    test "won't get friend chat messages of deleted user", %{
      user: user,
      user2: %{id: user2_id},
      user3: user3
    } do
      {:ok, _result} = OmegaBravera.Accounts.gdpr_delete_user(user3.id)
      assert [%{id: ^user2_id}] = Accounts.list_accepted_friends_with_chat_messages(user.id)
    end
  end
end
