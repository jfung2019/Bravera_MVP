defmodule OmegaBravera.NotificationsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.{Notifications, Accounts}
  alias Notifications.Device

  @user_create_attrs %{
    email: "sherief@plangora.com",
    firstname: "firstname",
    lastname: "lastname",
    location_id: 1
  }

  def user_fixture(_) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)

    {:ok, user: user}
  end

  def device_fixture(%{user: %{id: user_id}}) do
    {:ok, device: OmegaBravera.Fixtures.notification_device_fixture(%{user_id: user_id})}
  end

  def email_category_fixture(attrs \\ %{}) do
    {:ok, email_category} =
      attrs
      |> Notifications.create_email_category()

    email_category
  end

  defp create_email_category(_) do
    email_category =
      email_category_fixture(%{description: "some description", title: "some title"})

    {:ok, email_category: email_category}
  end

  describe "email_categories" do
    setup [:create_email_category]

    alias OmegaBravera.Notifications.EmailCategory

    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    test "list_email_categories/0 returns all email_categories" do
      assert length(Notifications.list_email_categories()) == 6
    end

    test "get_email_category!/1 returns the email_category with given id", %{
      email_category: email_category
    } do
      assert Notifications.get_email_category!(email_category.id) == email_category
    end

    test "create_email_category/1 with valid data creates a email_category" do
      assert {:ok, %EmailCategory{} = email_category} =
               Notifications.create_email_category(@valid_attrs)

      assert email_category.description == "some description"
      assert email_category.title == "some title"
    end

    test "create_email_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_email_category(@invalid_attrs)
    end

    test "update_email_category/2 with valid data updates the email_category", %{
      email_category: email_category
    } do
      assert {:ok, %EmailCategory{} = email_category} =
               Notifications.update_email_category(email_category, @update_attrs)

      assert email_category.description == "some updated description"
      assert email_category.title == "some updated title"
    end

    test "update_email_category/2 with invalid data returns error changeset", %{
      email_category: email_category
    } do
      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_email_category(email_category, @invalid_attrs)

      assert email_category == Notifications.get_email_category!(email_category.id)
    end

    test "delete_email_category/1 deletes the email_category", %{email_category: email_category} do
      assert {:ok, %EmailCategory{}} = Notifications.delete_email_category(email_category)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_email_category!(email_category.id)
      end
    end

    test "change_email_category/1 returns a email_category changeset", %{
      email_category: email_category
    } do
      assert %Ecto.Changeset{} = Notifications.change_email_category(email_category)
    end
  end

  describe "sendgrid_emails" do
    setup [:create_email_category]

    alias OmegaBravera.Notifications.SendgridEmail

    @valid_attrs %{sendgrid_id: "some sendgrid_id"}
    @update_attrs %{sendgrid_id: "some updated sendgrid_id"}
    @invalid_attrs %{sendgrid_id: nil}

    def sendgrid_email_fixture(attrs \\ %{}) do
      {:ok, sendgrid_email} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notifications.create_sendgrid_email()

      sendgrid_email
    end

    test "list_sendgrid_emails/0 returns all sendgrid_emails" do
      assert length(Notifications.list_sendgrid_emails()) == 20
    end

    test "get_sendgrid_email!/1 returns the sendgrid_email with given id", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert Notifications.get_sendgrid_email!(sendgrid_email.id) == sendgrid_email
    end

    test "create_sendgrid_email/1 with valid data creates a sendgrid_email", %{
      email_category: email_category
    } do
      attrs = Map.put(@valid_attrs, :category_id, email_category.id)
      assert {:ok, %SendgridEmail{} = sendgrid_email} = Notifications.create_sendgrid_email(attrs)
      assert sendgrid_email.sendgrid_id == "some sendgrid_id"
    end

    test "create_sendgrid_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_sendgrid_email(@invalid_attrs)
    end

    test "update_sendgrid_email/2 with valid data updates the sendgrid_email", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})

      assert {:ok, %SendgridEmail{} = sendgrid_email} =
               Notifications.update_sendgrid_email(sendgrid_email, @update_attrs)

      assert sendgrid_email.sendgrid_id == "some updated sendgrid_id"
    end

    test "update_sendgrid_email/2 with invalid data returns error changeset", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_sendgrid_email(sendgrid_email, @invalid_attrs)

      assert sendgrid_email == Notifications.get_sendgrid_email!(sendgrid_email.id)
    end

    test "delete_sendgrid_email/1 deletes the sendgrid_email", %{email_category: email_category} do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert {:ok, %SendgridEmail{}} = Notifications.delete_sendgrid_email(sendgrid_email)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_sendgrid_email!(sendgrid_email.id)
      end
    end

    test "change_sendgrid_email/1 returns a sendgrid_email changeset", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert %Ecto.Changeset{} = Notifications.change_sendgrid_email(sendgrid_email)
    end
  end

  describe "user_email_categories" do
    setup [:create_email_category, :user_fixture]

    alias OmegaBravera.Notifications.UserEmailCategories

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{user_id: nil, category_id: nil}

    def user_email_categories_fixture(attrs \\ %{}) do
      {:ok, user_email_categories} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notifications.create_user_email_categories()

      user_email_categories
    end

    test "list_user_email_categories/0 returns all user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert Notifications.list_user_email_categories() == [user_email_categories]
    end

    test "get_user_email_categories!/1 returns the user_email_categories with given id", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert Notifications.get_user_email_categories!(user_email_categories.id) ==
               user_email_categories
    end

    test "create_user_email_categories/1 with valid data creates a user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      assert {:ok, %UserEmailCategories{}} =
               Notifications.create_user_email_categories(%{
                 category_id: email_category.id,
                 user_id: user.id
               })
    end

    test "create_user_email_categories/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_user_email_categories(@invalid_attrs)
    end

    test "update_user_email_categories/2 with valid data updates the user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:ok, %UserEmailCategories{}} =
               Notifications.update_user_email_categories(user_email_categories, @update_attrs)
    end

    test "update_user_email_categories/2 with invalid data returns error changeset", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_user_email_categories(user_email_categories, @invalid_attrs)

      assert user_email_categories ==
               Notifications.get_user_email_categories!(user_email_categories.id)
    end

    test "delete_user_email_categories/1 deletes the user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:ok, %UserEmailCategories{}} =
               Notifications.delete_user_email_categories(user_email_categories)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_user_email_categories!(user_email_categories.id)
      end
    end

    test "change_user_email_categories/1 returns a user_email_categories changeset", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert %Ecto.Changeset{} = Notifications.change_user_email_categories(user_email_categories)
    end
  end

  describe "notification_devices" do
    setup [:user_fixture]

    test "create_device/1 with valid data creates a device", %{user: %{id: user_id}} do
      assert {:ok, %Device{} = device} =
               Notifications.create_device(%{token: "123", user_id: user_id})

      assert device.token == "123"
    end

    test "create_device/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_device(%{token: nil})
    end
  end

  describe "notification_device created" do
    setup [:user_fixture, :device_fixture]

    test "cannot create same device for same user", %{device: device} do
      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_device(%{token: device.token, user_id: device.user_id})
    end

    test "list_notification_devices/0 returns all notification_devices", %{device: device} do
      assert Notifications.list_notification_devices() == [device]
    end

    test "get_device!/1 returns the device with given id", %{device: device} do
      assert Notifications.get_device!(device.id) == device
    end

    test "update_device/2 with valid data updates the device", %{device: device} do
      assert {:ok, %Device{} = device} =
               Notifications.update_device(device, %{token: "updatedtoken"})

      assert device.token == "updatedtoken"
    end

    test "update_device/2 with invalid data returns error changeset", %{device: device} do
      assert {:error, %Ecto.Changeset{}} = Notifications.update_device(device, %{token: nil})
      assert device == Notifications.get_device!(device.id)
    end

    test "delete_device/1 deletes the device", %{device: device} do
      assert {:ok, %Device{}} = Notifications.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Notifications.get_device!(device.id) end
    end

    test "change_device/1 returns a device changeset", %{device: device} do
      assert %Ecto.Changeset{} = Notifications.change_device(device)
    end
  end
end
