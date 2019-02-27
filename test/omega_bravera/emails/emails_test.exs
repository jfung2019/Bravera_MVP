defmodule OmegaBravera.EmailsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.{Emails, Accounts}

  @user_create_attrs %{
    email: "sherief@plangora.com",
    firstname: "firstname",
    lastname: "lastname"
  }

  def user_fixture(_) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)

    {:ok, user: user}
  end

  def email_category_fixture(attrs \\ %{}) do
    {:ok, email_category} =
      attrs
      |> Emails.create_email_category()

    email_category
  end

  defp create_email_category(_) do
    email_category =
      email_category_fixture(%{description: "some description", title: "some title"})

    {:ok, email_category: email_category}
  end

  describe "email_categories" do
    setup [:create_email_category]

    alias OmegaBravera.Emails.EmailCategory

    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    test "list_email_categories/0 returns all email_categories" do
      assert length(Emails.list_email_categories()) == 6
    end

    test "get_email_category!/1 returns the email_category with given id", %{
      email_category: email_category
    } do
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

    test "update_email_category/2 with valid data updates the email_category", %{
      email_category: email_category
    } do
      assert {:ok, %EmailCategory{} = email_category} =
               Emails.update_email_category(email_category, @update_attrs)

      assert email_category.description == "some updated description"
      assert email_category.title == "some updated title"
    end

    test "update_email_category/2 with invalid data returns error changeset", %{
      email_category: email_category
    } do
      assert {:error, %Ecto.Changeset{}} =
               Emails.update_email_category(email_category, @invalid_attrs)

      assert email_category == Emails.get_email_category!(email_category.id)
    end

    test "delete_email_category/1 deletes the email_category", %{email_category: email_category} do
      assert {:ok, %EmailCategory{}} = Emails.delete_email_category(email_category)
      assert_raise Ecto.NoResultsError, fn -> Emails.get_email_category!(email_category.id) end
    end

    test "change_email_category/1 returns a email_category changeset", %{
      email_category: email_category
    } do
      assert %Ecto.Changeset{} = Emails.change_email_category(email_category)
    end
  end

  describe "sendgrid_emails" do
    setup [:create_email_category]

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

    test "list_sendgrid_emails/0 returns all sendgrid_emails", %{email_category: email_category} do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert Emails.list_sendgrid_emails() == [sendgrid_email]
    end

    test "get_sendgrid_email!/1 returns the sendgrid_email with given id", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert Emails.get_sendgrid_email!(sendgrid_email.id) == sendgrid_email
    end

    test "create_sendgrid_email/1 with valid data creates a sendgrid_email", %{
      email_category: email_category
    } do
      attrs = Map.put(@valid_attrs, :category_id, email_category.id)
      assert {:ok, %SendgridEmail{} = sendgrid_email} = Emails.create_sendgrid_email(attrs)
      assert sendgrid_email.sendgrid_id == "some sendgrid_id"
    end

    test "create_sendgrid_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Emails.create_sendgrid_email(@invalid_attrs)
    end

    test "update_sendgrid_email/2 with valid data updates the sendgrid_email", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})

      assert {:ok, %SendgridEmail{} = sendgrid_email} =
               Emails.update_sendgrid_email(sendgrid_email, @update_attrs)

      assert sendgrid_email.sendgrid_id == "some updated sendgrid_id"
    end

    test "update_sendgrid_email/2 with invalid data returns error changeset", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})

      assert {:error, %Ecto.Changeset{}} =
               Emails.update_sendgrid_email(sendgrid_email, @invalid_attrs)

      assert sendgrid_email == Emails.get_sendgrid_email!(sendgrid_email.id)
    end

    test "delete_sendgrid_email/1 deletes the sendgrid_email", %{email_category: email_category} do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert {:ok, %SendgridEmail{}} = Emails.delete_sendgrid_email(sendgrid_email)
      assert_raise Ecto.NoResultsError, fn -> Emails.get_sendgrid_email!(sendgrid_email.id) end
    end

    test "change_sendgrid_email/1 returns a sendgrid_email changeset", %{
      email_category: email_category
    } do
      sendgrid_email = sendgrid_email_fixture(%{category_id: email_category.id})
      assert %Ecto.Changeset{} = Emails.change_sendgrid_email(sendgrid_email)
    end
  end

  describe "user_email_categories" do
    setup [:create_email_category, :user_fixture]

    alias OmegaBravera.Emails.UserEmailCategories

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{user_id: nil, category_id: nil}

    def user_email_categories_fixture(attrs \\ %{}) do
      {:ok, user_email_categories} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Emails.create_user_email_categories()

      user_email_categories
    end

    test "list_user_email_categories/0 returns all user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert Emails.list_user_email_categories() == [user_email_categories]
    end

    test "get_user_email_categories!/1 returns the user_email_categories with given id", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert Emails.get_user_email_categories!(user_email_categories.id) == user_email_categories
    end

    test "create_user_email_categories/1 with valid data creates a user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      assert {:ok, %UserEmailCategories{} = user_email_categories} =
               Emails.create_user_email_categories(%{
                 category_id: email_category.id,
                 user_id: user.id
               })
    end

    test "create_user_email_categories/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Emails.create_user_email_categories(@invalid_attrs)
    end

    test "update_user_email_categories/2 with valid data updates the user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:ok, %UserEmailCategories{} = user_email_categories} =
               Emails.update_user_email_categories(user_email_categories, @update_attrs)
    end

    test "update_user_email_categories/2 with invalid data returns error changeset", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:error, %Ecto.Changeset{}} =
               Emails.update_user_email_categories(user_email_categories, @invalid_attrs)

      assert user_email_categories == Emails.get_user_email_categories!(user_email_categories.id)
    end

    test "delete_user_email_categories/1 deletes the user_email_categories", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert {:ok, %UserEmailCategories{}} =
               Emails.delete_user_email_categories(user_email_categories)

      assert_raise Ecto.NoResultsError, fn ->
        Emails.get_user_email_categories!(user_email_categories.id)
      end
    end

    test "change_user_email_categories/1 returns a user_email_categories changeset", %{
      email_category: email_category,
      user: user
    } do
      user_email_categories =
        user_email_categories_fixture(%{category_id: email_category.id, user_id: user.id})

      assert %Ecto.Changeset{} = Emails.change_user_email_categories(user_email_categories)
    end
  end
end
