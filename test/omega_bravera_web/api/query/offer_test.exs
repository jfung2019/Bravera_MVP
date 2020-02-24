defmodule OmegaBraveraWeb.Api.Query.OfferTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @all_offers_images_query """
  query {
    allOffers {
      image
      images
    }
  }
  """
  @get_offers_images_query_by_slug """
  query ($slug: String!){
    getOffer(slug: $slug) {
      images
      image
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

  setup do
    credential = credential_fixture()
    offer = insert(:offer, %{target: 15, images: ["url1", "url2"], image: "url3"})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, token: auth_token, offer: offer}
  end

  test "images should be a list of urls and image should be the first image from that url in all offers",
       %{
         token: token
       } do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @all_offers_images_query})

    assert %{
             "data" => %{
               "allOffers" => [
                 %{
                   "image" => "url3",
                   "images" => ["url1", "url2"]
                 }
               ]
             }
           } = json_response(response, 200)
  end

  test "images should be a list of urls and image should be the first image from that url in a particular offer",
       %{
         token: token,
         offer: offer
       } do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")

    response =
      post(conn, "/api", %{
        query: @get_offers_images_query_by_slug,
        variables: %{"slug" => offer.slug}
      })

    assert %{
             "data" => %{
               "getOffer" => %{
                 "image" => "url3",
                 "images" => ["url1", "url2"]
               }
             }
           } = json_response(response, 200)
  end
end
