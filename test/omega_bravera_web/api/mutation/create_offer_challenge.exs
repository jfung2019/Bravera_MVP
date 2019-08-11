defmodule OmegaBraveraWeb.Api.Mutation.CreateOfferChallenge do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation ($offer_challenge: OfferChallengeCreateInput!) {
    createOfferChallenge(input: $offer_challenge){
      offerChallenge{
        id
        slug
        hasTeam
      }
      errors { key message }
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

  test "create/3 requires a user login to create offer challenge" do
    conn = build_conn()
    offer = insert(:offer)

    conn =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => offer.slug}}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "createOfferChallenge" => %{
                 "errors" => [
                   %{"key" => "user_id", "message" => "Action Requires Login"}
                 ],
                 "offerChallenge" => nil
               }
             }
           }
  end

  test "create/3 requires correct params to create offer challenge" do
    credential = credential_fixture()
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    conn = build_conn() |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)

    response =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => "kfc"}}
      })

    assert response.resp_body =~ "Offer not found"
  end

  test "create/3 creates offer challenges if correct params are given" do
    credential = credential_fixture()
    offer = insert(:offer)
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    conn = build_conn() |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)

    response =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => offer.slug}}
      })

    assert response.resp_body =~ "\"hasTeam\":false"
  end
end
