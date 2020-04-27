defmodule OmegaBraveraWeb.Api.Query.OfferRedeemTest do
  use OmegaBraveraWeb.ConnCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"

  @query """
  query {
    expiredRedeems {
      insertedAt
      offer {
        name
      }
      offerChallenge {
        id
      }
      status
      token
      updatedAt
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})

    credential_attrs = %{
      password: @password,
      password_confirmation: @password
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
      |> Repo.insert()

    credential = credential |> Repo.preload(:user)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "can get expired redeems", %{conn: conn} do
    response = post(conn, "/api", %{query: @query})
    assert %{"data" => %{"expiredRedeems" => []}} = json_response(response, 200)
  end
end
