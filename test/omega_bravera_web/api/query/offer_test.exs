defmodule OmegaBraveraWeb.Api.Query.OfferTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}
  alias OmegaBravera.Offers

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @images_query """
  query {
    allOffers {
      image
      images
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
    offer = insert(:offer, %{target: 15, images: ["url1", "url2"]})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, token: auth_token, offer: offer}
  end

  test "images should be a list of urls and image should be the first image from that url", %{
    token: token,
    offer: offer
  } do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @images_query})

    assert %{
             "data" => %{
               "allOffers" => [
                 %{
                   "image" => "url1",
                   "images" => ["url1", "url2"]
                 }
               ]
             }
           } = json_response(response, 200)
  end
end
