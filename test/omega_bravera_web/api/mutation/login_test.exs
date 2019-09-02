defmodule OmegaBraveraWeb.Api.Mutation.LoginTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation ($email: String!, $password: String!) {
    login(email: $email, password: $password) {
      errors { key message }
      userSession{
        token
        user{
          firstname
          lastname
        }
      }
    }
  }
  """
  def credential_fixture() do
    user = insert(:user, %{email: @email})

    credential_attrs = %{
      password: @password,
      password_confirmation: @password
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
      |> Repo.insert()

    credential |> Repo.preload(:user)
  end

  test "creating a user session" do
    credential = credential_fixture()

    response =
      post(build_conn(), "/api", %{
        query: @query,
        variables: %{"email" => @email, "password" => @password}
      })

    assert %{"data" => %{"login" => %{"userSession" => %{"token" => token, "user" => user_data}}}} =
             json_response(response, 200)

    assert %{"firstname" => credential.user.firstname, "lastname" => credential.user.lastname} ==
             user_data

    guardian_sub = "user:#{credential.user_id}"
    assert {:ok, %{"sub" => ^guardian_sub}} = OmegaBravera.Guardian.decode_and_verify(token)
  end
end
