defmodule OmegaBravera.EmailsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Emails

  describe "email_categories" do
    alias OmegaBravera.Emails.EmailCategory

    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    def email_category_fixture(attrs \\ %{}) do
      {:ok, email_category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Emails.create_email_category()

      email_category
    end

    test "list_email_categories/0 returns all email_categories" do
      email_category = email_category_fixture()
      assert Emails.list_email_categories() == [email_category]
    end

    test "get_email_category!/1 returns the email_category with given id" do
      email_category = email_category_fixture()
      assert Emails.get_email_category!(email_category.id) == email_category
    end

    test "create_email_category/1 with valid data creates a email_category" do
      assert {:ok, %EmailCategory{} = email_category} = Emails.create_email_category(@valid_attrs)
      assert email_category.description == "some description"
      assert email_category.title == "some title"
    end

    test "create_email_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Emails.create_email_category(@invalid_attrs)
    end

    test "update_email_category/2 with valid data updates the email_category" do
      email_category = email_category_fixture()
      assert {:ok, %EmailCategory{} = email_category} = Emails.update_email_category(email_category, @update_attrs)
      assert email_category.description == "some updated description"
      assert email_category.title == "some updated title"
    end

    test "update_email_category/2 with invalid data returns error changeset" do
      email_category = email_category_fixture()
      assert {:error, %Ecto.Changeset{}} = Emails.update_email_category(email_category, @invalid_attrs)
      assert email_category == Emails.get_email_category!(email_category.id)
    end

    test "delete_email_category/1 deletes the email_category" do
      email_category = email_category_fixture()
      assert {:ok, %EmailCategory{}} = Emails.delete_email_category(email_category)
      assert_raise Ecto.NoResultsError, fn -> Emails.get_email_category!(email_category.id) end
    end

    test "change_email_category/1 returns a email_category changeset" do
      email_category = email_category_fixture()
      assert %Ecto.Changeset{} = Emails.change_email_category(email_category)
    end
  end

  describe "sendgrid_emails" do
    alias OmegaBravera.Emails.SendgridEmail

    @valid_attrs %{sendgrid_id: "some sendgrid_id"}
    @update_attrs %{sendgrid_id: "some updated sendgrid_id"}
    @invalid_attrs %{sendgrid_id: nil}

    def sendgrid_email_fixture(attrs \\ %{}) do
      {:ok, sendgrid_email} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Emails.create_sendgrid_email()

      sendgrid_email
    end

    test "list_sendgrid_emails/0 returns all sendgrid_emails" do
      sendgrid_email = sendgrid_email_fixture()
      assert Emails.list_sendgrid_emails() == [sendgrid_email]
    end

    test "get_sendgrid_email!/1 returns the sendgrid_email with given id" do
      sendgrid_email = sendgrid_email_fixture()
      assert Emails.get_sendgrid_email!(sendgrid_email.id) == sendgrid_email
    end

    test "create_sendgrid_email/1 with valid data creates a sendgrid_email" do
      assert {:ok, %SendgridEmail{} = sendgrid_email} = Emails.create_sendgrid_email(@valid_attrs)
      assert sendgrid_email.sendgrid_id == "some sendgrid_id"
    end

    test "create_sendgrid_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Emails.create_sendgrid_email(@invalid_attrs)
    end

    test "update_sendgrid_email/2 with valid data updates the sendgrid_email" do
      sendgrid_email = sendgrid_email_fixture()
      assert {:ok, %SendgridEmail{} = sendgrid_email} = Emails.update_sendgrid_email(sendgrid_email, @update_attrs)
      assert sendgrid_email.sendgrid_id == "some updated sendgrid_id"
    end

    test "update_sendgrid_email/2 with invalid data returns error changeset" do
      sendgrid_email = sendgrid_email_fixture()
      assert {:error, %Ecto.Changeset{}} = Emails.update_sendgrid_email(sendgrid_email, @invalid_attrs)
      assert sendgrid_email == Emails.get_sendgrid_email!(sendgrid_email.id)
    end

    test "delete_sendgrid_email/1 deletes the sendgrid_email" do
      sendgrid_email = sendgrid_email_fixture()
      assert {:ok, %SendgridEmail{}} = Emails.delete_sendgrid_email(sendgrid_email)
      assert_raise Ecto.NoResultsError, fn -> Emails.get_sendgrid_email!(sendgrid_email.id) end
    end

    test "change_sendgrid_email/1 returns a sendgrid_email changeset" do
      sendgrid_email = sendgrid_email_fixture()
      assert %Ecto.Changeset{} = Emails.change_sendgrid_email(sendgrid_email)
    end
  end

  describe "user_email_categories" do
    alias OmegaBravera.Emails.UserEmailCategories

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def user_email_categories_fixture(attrs \\ %{}) do
      {:ok, user_email_categories} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Emails.create_user_email_categories()

      user_email_categories
    end

    test "list_user_email_categories/0 returns all user_email_categories" do
      user_email_categories = user_email_categories_fixture()
      assert Emails.list_user_email_categories() == [user_email_categories]
    end

    test "get_user_email_categories!/1 returns the user_email_categories with given id" do
      user_email_categories = user_email_categories_fixture()
      assert Emails.get_user_email_categories!(user_email_categories.id) == user_email_categories
    end

    test "create_user_email_categories/1 with valid data creates a user_email_categories" do
      assert {:ok, %UserEmailCategories{} = user_email_categories} = Emails.create_user_email_categories(@valid_attrs)
    end

    test "create_user_email_categories/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Emails.create_user_email_categories(@invalid_attrs)
    end

    test "update_user_email_categories/2 with valid data updates the user_email_categories" do
      user_email_categories = user_email_categories_fixture()
      assert {:ok, %UserEmailCategories{} = user_email_categories} = Emails.update_user_email_categories(user_email_categories, @update_attrs)
    end

    test "update_user_email_categories/2 with invalid data returns error changeset" do
      user_email_categories = user_email_categories_fixture()
      assert {:error, %Ecto.Changeset{}} = Emails.update_user_email_categories(user_email_categories, @invalid_attrs)
      assert user_email_categories == Emails.get_user_email_categories!(user_email_categories.id)
    end

    test "delete_user_email_categories/1 deletes the user_email_categories" do
      user_email_categories = user_email_categories_fixture()
      assert {:ok, %UserEmailCategories{}} = Emails.delete_user_email_categories(user_email_categories)
      assert_raise Ecto.NoResultsError, fn -> Emails.get_user_email_categories!(user_email_categories.id) end
    end

    test "change_user_email_categories/1 returns a user_email_categories changeset" do
      user_email_categories = user_email_categories_fixture()
      assert %Ecto.Changeset{} = Emails.change_user_email_categories(user_email_categories)
    end
  end
end
