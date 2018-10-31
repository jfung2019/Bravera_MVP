defmodule OmegaBravera.AccountsTest do
  use OmegaBravera.DataCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Accounts.User, Repo, Trackers.Strava, Accounts.Credential}

  describe "users" do
    @valid_attrs %{email: "test@test.com", firstname: "some firstname", lastname: "some lastname"}
    @update_attrs %{
      email: "updated_test@test.com",
      firstname: "some updated firstname",
      lastname: "some updated lastname"
    }
    @invalid_attrs %{email: nil, firstname: nil, lastname: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "donors_for_challenge/1 returns all donors for a challenge" do
      user = insert(:user)
      ngo = insert(:ngo, %{slug: "swcc-1"})
      challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})

      # 2 famous runners
      matthew_wells =
        insert(:user, %{firstname: "Matthew", lastname: "Wells", email: "matthew.wells@test.com"})

      carlos_cordero =
        insert(:user, %{
          firstname: "Carlos",
          lastname: "Cordero",
          email: "carlos.cordero@test.com"
        })

      insert(:donation, %{ngo_chal: challenge, ngo: ngo, user: carlos_cordero})
      insert(:donation, %{ngo_chal: challenge, ngo: ngo, user: matthew_wells})

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
      _strava = insert(:strava, Map.merge(user_attrs, %{token: "abcdef", user: user}))

      attrs = %{
        athlete_id: 33_762_738,
        email: "simon.garciar@gmail.com",
        firstname: "Rafael",
        lastname: "Garcia",
        token: "87318aaded9cdeb99a1a3c20c6af26ccf059de30",
        additional_info: %{sex: "M", location: "Spain/Barcelona/Barcelona"}
      }

      {:ok, user} = Accounts.insert_or_update_strava_user(attrs)

      user = Repo.preload(user, [:strava])

      assert user.additional_info[:sex] == "M"
      assert user.additional_info[:location] == "Spain/Barcelona/Barcelona"
      assert user.strava.athlete_id == 33_762_738
      assert user.strava.token == "87318aaded9cdeb99a1a3c20c6af26ccf059de30"
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "test@test.com"
      assert user.firstname == "some firstname"
      assert user.lastname == "some lastname"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "updated_test@test.com"
      assert user.firstname == "some updated firstname"
      assert user.lastname == "some updated lastname"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "settings" do
    alias OmegaBravera.Accounts.Setting

    @valid_attrs %{
      email_notifications: true,
      facebook: "some facebook",
      instagram: "some instagram",
      location: "some location",
      request_delete: true,
      show_lastname: true,
      twitter: "some twitter"
    }
    @update_attrs %{
      email_notifications: false,
      facebook: "some updated facebook",
      instagram: "some updated instagram",
      location: "some updated location",
      request_delete: false,
      show_lastname: false,
      twitter: "some updated twitter"
    }
    @invalid_attrs %{
      email_notifications: nil,
      facebook: nil,
      instagram: nil,
      location: nil,
      request_delete: nil,
      show_lastname: nil,
      twitter: nil
    }

    def setting_fixture(attrs \\ %{}) do
      {:ok, setting} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_setting()

      setting
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
      assert {:ok, %Setting{} = setting} = Accounts.create_setting(@valid_attrs)
      assert setting.email_notifications == true
      assert setting.facebook == "some facebook"
      assert setting.instagram == "some instagram"
      assert setting.location == "some location"
      assert setting.request_delete == true
      assert setting.show_lastname == true
      assert setting.twitter == "some twitter"
    end

    test "create_setting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_setting(@invalid_attrs)
    end

    test "update_setting/2 with valid data updates the setting" do
      setting = setting_fixture()
      assert {:ok, setting} = Accounts.update_setting(setting, @update_attrs)
      assert %Setting{} = setting
      assert setting.email_notifications == false
      assert setting.facebook == "some updated facebook"
      assert setting.instagram == "some updated instagram"
      assert setting.location == "some updated location"
      assert setting.request_delete == false
      assert setting.show_lastname == false
      assert setting.twitter == "some updated twitter"
    end

    test "update_setting/2 with invalid data returns error changeset" do
      setting = setting_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_setting(setting, @invalid_attrs)
      assert setting == Accounts.get_setting!(setting.id)
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
    alias OmegaBravera.Accounts.AdminUser

    @valid_attrs %{email: "some email", password: "pass1234"}
    @update_attrs %{email: "some updated email", password_hash: "nopass1234"}
    @invalid_attrs %{email: nil, password_hash: nil}

    def admin_user_fixture(attrs \\ %{}) do
      {:ok, admin_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_admin_user()

      admin_user
    end

    test "list_admin_users/0 returns all admin_users" do
      admin_user = %{admin_user_fixture() | password: nil}
      assert Accounts.list_admin_users() == [admin_user]
    end

    test "get_admin_user!/1 returns the admin_user with given id" do
      admin_user = %{admin_user_fixture() | password: nil}
      assert Accounts.get_admin_user!(admin_user.id) == admin_user
    end

    test "create_admin_user/1 with valid data creates a admin_user" do
      assert {:ok, %AdminUser{} = admin_user} = Accounts.create_admin_user(@valid_attrs)
      assert admin_user.email == "some email"
    end

    test "create_admin_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_admin_user(@invalid_attrs)
    end

    test "update_admin_user/2 with valid data updates the admin_user" do
      admin_user = admin_user_fixture()
      assert {:ok, admin_user} = Accounts.update_admin_user(admin_user, @update_attrs)
      assert %AdminUser{} = admin_user
      assert admin_user.email == "some updated email"
    end

    test "update_admin_user/2 with invalid data returns error changeset" do
      admin_user = %{admin_user_fixture() | password: nil}
      assert {:error, %Ecto.Changeset{}} = Accounts.update_admin_user(admin_user, @invalid_attrs)
      assert admin_user == Accounts.get_admin_user!(admin_user.id)
    end

    test "delete_admin_user/1 deletes the admin_user" do
      admin_user = admin_user_fixture()
      assert {:ok, %AdminUser{}} = Accounts.delete_admin_user(admin_user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_admin_user!(admin_user.id) end
    end

    test "change_admin_user/1 returns a admin_user changeset" do
      admin_user = admin_user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_admin_user(admin_user)
    end
  end

  describe "authenticat_admin_user_by_email_and_pass/2" do
    @email "user@localhost"
    @pass "123456"

    alias OmegaBravera.Accounts.AdminUser

    setup do
      {:ok, user: admin_user_fixture(email: @email, password: @pass)}
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
    @password "strong password"

    def credential_fixture() do
      user = insert(:user)

      credential_attrs = %{
        password: @password,
        password_confirmation: @password,
        user_id: user.id
      }

      {:ok, credential} =
        Credential.changeset(%Credential{}, credential_attrs)
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
end
