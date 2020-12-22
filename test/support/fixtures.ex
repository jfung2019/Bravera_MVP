defmodule OmegaBravera.Fixtures do
  alias OmegaBravera.{Accounts, Repo, Groups, Notifications}
  alias OmegaBravera.Accounts.Credential

  def partner_fixture(attrs \\ %{}) do
    {:ok, partner} =
      attrs
      |> Enum.into(%{
        images: [],
        introduction: "some introduction",
        name: "some name",
        short_description: "some opening_times",
        live: true
      })
      |> Groups.create_partner()

    partner
  end

  def partner_location_fixture(attrs \\ %{}) do
    {:ok, partner_location} =
      attrs
      |> Enum.into(%{address: "some address", latitude: "120.5", longitude: "120.5"})
      |> Groups.create_partner_location()

    partner_location
  end

  def credential_fixture(user_id) do
    credential_attrs = %{
      password: "testies123",
      password_confirmation: "testies123"
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user_id}, credential_attrs)
      |> Repo.insert()

    credential
    |> Repo.preload(:user)
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test@test.com",
        firstname: "some firstname",
        lastname: "some lastname",
        location_id: 1
      })
      |> Accounts.create_user()

    user
  end

  def partner_vote_fixture(attrs) do
    {:ok, vote} = Groups.create_partner_vote(attrs)
    vote
  end

  def admin_user_fixture(attrs \\ %{}) do
    {:ok, admin_user} =
      attrs
      |> Enum.into(%{email: "some@email.com", password: "pass1234"})
      |> Accounts.create_admin_user()

    admin_user
  end

  def notification_device_fixture(attrs \\ %{}) do
    {:ok, device} =
      attrs
      |> Enum.into(%{token: "token"})
      |> Notifications.create_device()

    device
  end

  def group_chat_message_fixture(attrs \\ %{}) do
    {:ok, chat_message} =
      attrs
      |> Enum.into(%{message: "some message", meta_data: %{}})
      |> Groups.create_chat_message()

    chat_message
  end

  def partner_user_fixture(attrs \\ %{}) do
    {:ok, partner_user} =
      attrs
      |> Enum.into(%{
        business_type: "some biz",
        username: "partner_user1",
        email: "some@email.com",
        password: "pass1234"
      })
      |> Accounts.create_partner_user()

    partner_user
  end
end
