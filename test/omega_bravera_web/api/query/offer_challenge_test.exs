defmodule OmegaBraveraWeb.Api.Query.OfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  query {
    expiredChallenges {
      id
      slug
      hasTeam
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

  setup %{conn: conn} do
    credential = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "create/3 requires a user login to create offer challenge", %{conn: conn} do
    response = post(conn, "/api", %{query: @query})
    assert %{"data" => %{"expiredChallenges" => []}} = json_response(response, 200)
  end
end
