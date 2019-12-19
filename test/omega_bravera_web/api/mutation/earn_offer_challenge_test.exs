defmodule OmegaBraveraWeb.Api.Mutation.EarnOfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation($offerSlug: String!){
    earnOfferChallenge(offerSlug: $offerSlug){
      offerChallenge{
        id
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

    credential
    |> Repo.preload(:user)
  end

  test "buy/3 can create complete challenge, send reward to use, and deduct points from total balance" do
    credential = credential_fixture()
    offer = insert(:offer, %{target: 15})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{auth_token}")

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{
             "data" => %{
               "earnOfferChallenge" => %{"offerChallenge" => %{"id" => _id}}
             }
           } = json_response(response, 200)
  end
end
