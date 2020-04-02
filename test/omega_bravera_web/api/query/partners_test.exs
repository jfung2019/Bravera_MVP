defmodule OmegaBraveraWeb.Api.Query.PartnersTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @location_query """
  query {
    partnerLocations {
      address
      latitude
      longitude
      partner {
        name
        introduction
        votes {
          user {
            id
            profilePicture
          }
        }
        offers {
          name
        }
      }
    }
  }
  """

  @partner_query """
  query($partnerId: ID!) {
    getPartner(partnerId: $partnerId) {
      name
      introduction
      votes {
        user {
          id
          profilePicture
        }
      }
      offers {
        name
      }
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user)
    credential = Fixtures.credential_fixture(user.id)
    partner = Fixtures.partner_fixture()
    Fixtures.partner_location_fixture(%{partner_id: partner.id})
    insert(:offer, %{partner_id: partner.id})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     partner: partner}
  end

  test "can get partner locations, partner and their offers", %{conn: conn} do
    response = post(conn, "/api", %{query: @location_query})
    assert %{"data" => %{"partnerLocations" => [_location]}} = json_response(response, 200)
  end

  test "can get partner by their id", %{conn: conn, partner: %{id: partner_id, name: name}} do
    response =
      post(conn, "/api", %{query: @partner_query, variables: %{"partnerId" => partner_id}})

    assert %{"data" => %{"getPartner" => %{"name" => ^name}}} = json_response(response, 200)
  end
end
