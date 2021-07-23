defmodule OmegaBraveraWeb.Api.Query.OfferTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @get_offers_images_query_by_slug """
  query ($slug: String!){
    getOffer(slug: $slug) {
      takeChallenge
      images
      image
      logo
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    offer = insert(:offer, %{target: 15, images: ["url1", "url2"], image: "url3"})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, offer: offer, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "images should be a list of urls and image should be the first image from that url in a particular offer",
       %{
         conn: conn,
         offer: offer
       } do
    response =
      post(conn, "/api", %{
        query: @get_offers_images_query_by_slug,
        variables: %{"slug" => offer.slug}
      })

    assert %{
             "data" => %{
               "getOffer" => %{
                 "image" => "url1",
                 "logo" => "url1",
                 "images" => ["url1", "url2"]
               }
             }
           } = json_response(response, 200)
  end
end
