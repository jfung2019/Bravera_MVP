defmodule OmegaBraveraWeb.Api.Query.GroupsTest do
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
        isMember
        shortDescription
        openingTimes
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

  @partners_query """
  query {
    getPartners {
      name
      introduction
      isMember
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

  @partner_query """
  query($partnerId: ID!) {
    getPartner(partnerId: $partnerId) {
      name
      introduction
      isMember
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

  @search_groups """
  query($keyword: String!) {
    searchGroups(keyword: $keyword) {
      name
      introduction
      isMember
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
    %{id: offer_id} = insert(:offer)
    OmegaBravera.Groups.create_offer_partner(%{partner_id: partner.id, offer_id: offer_id})
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

    assert %{"data" => %{"getPartner" => %{"name" => ^name, "isMember" => false}}} =
             json_response(response, 200)
  end

  test "can list all live partners", %{conn: conn, partner: %{name: name}} do
    response = post(conn, "/api", %{query: @partners_query})

    assert %{"data" => %{"getPartners" => [%{"name" => ^name, "isMember" => false}]}} =
             json_response(response, 200)
  end

  test "can search live partners by keyword", %{conn: conn, partner: %{name: name}} do
    OmegaBravera.Groups.create_partner(%{
      images: [],
      introduction: "intro",
      name: "second",
      short_description: "des",
      approval_status: :approved
    })

    response = post(conn, "/api", %{query: @search_groups, variables: %{"keyword" => "na"}})

    assert %{"data" => %{"searchGroups" => [%{"name" => ^name, "isMember" => false}]}} =
             json_response(response, 200)
  end
end
