defmodule OmegaBraveraWeb.Api.Query.OfferTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}
  alias OmegaBravera.Offers

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"

  @valid_attrs %{
    activities: [],
    additional_members: 42,
    currency: "gbp",
    desc: "some desc",
    target: 0,
    full_desc: "some full_desc",
    ga_id: "some ga_id",
    hidden: false,
    name: "some name",
    offer_challenge_desc: "some offer_challenge_desc",
    offer_challenge_types: [],
    offer_percent: 120.5,
    open_registration: true,
    slug: "some slug",
    toc: "some toc",
    url: "https://bravera.co",
    vendor_id: nil,
    start_date: Timex.now(),
    end_date: Timex.shift(Timex.now(), days: 5),
    payment_amount: Decimal.new(0),
    location_id: 1
  }

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

  def offer_fixture(attrs \\ %{}) do
    vendor = insert(:vendor)

    {:ok, offer} =
      attrs
      |> Enum.into(%{@valid_attrs | vendor_id: vendor.id})
      |> Offers.create_offer()

    offer
  end

  def create_offer(attrs) do
    attrs
    |> Map.put(:vendor_id, insert(:vendor).id)
    |> Map.put(:images, ["url1", "url2"])  
    |> Offers.create_offer()
  end

  setup do
    credential = credential_fixture()
    device = insert(:device, %{user_id: credential.user_id, active: true})
    token = OmegaBraveraWeb.Api.Auth.generate_device_token(device.uuid)
    offer = offer_fixture()
    {:ok, token: token, offer: offer}
  end

  test "images should be a list of urls and image should be the first image from that url", %{token: token, offer: offer} do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @images_query})

    assert %{
            "data" => %{
              "allOffers" => [%{
                "image" => "url1",
                "images" => ["url1", "url2"]
              }]
            }
          } = json_response(response, 200)
  end
end
