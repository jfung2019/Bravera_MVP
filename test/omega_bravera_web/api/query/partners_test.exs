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
  query($keyword: String, $global: Boolean!, $first: Integer!, $myGroup: Boolean) {
    searchGroupsPaginated(keyword: $keyword, global: $global, first: $first, myGroup: $myGroup) {
      edges {
        node {
          id
          name
          introduction
          images
          shortDescription
          votes {
            user {
              id
              profilePicture
            }
          }
          offers {
            name
            endDate
          }
        }
      }
    }
  }
  """

  setup %{conn: conn} do
    {:ok, location} =
      OmegaBravera.Locations.create_location(%{
        name_en: "some name_en",
        name_zh: "some name_zh",
        longitude: 90,
        latitude: 30
      })

    user = insert(:user, %{location_id: location.id})
    credential = Fixtures.credential_fixture(user.id)
    partner = Fixtures.partner_fixture()
    Fixtures.partner_location_fixture(%{partner_id: partner.id})
    %{id: offer_id} = insert(:offer)
    OmegaBravera.Groups.create_offer_partner(%{partner_id: partner.id, offer_id: offer_id})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     partner: partner,
     location: location,
     user: user}
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

  describe "searchGroupsPaginated" do
    setup %{location: location} do
      {:ok, partner2} =
        OmegaBravera.Groups.create_partner(%{
          images: [],
          introduction: "intro",
          name: "second",
          short_description: "des",
          approval_status: :approved,
          location_id: location.id
        })

      {:ok, partner3} =
        OmegaBravera.Groups.create_partner(%{
          images: [],
          introduction: "intro",
          name: "third",
          short_description: "des",
          approval_status: :approved,
          location_id: location.id
        })

      %{partner2: partner2, partner3: partner3}
    end

    test "can search live partners by keyword", %{conn: conn} do
      response =
        post(conn, "/api", %{
          query: @search_groups,
          variables: %{"keyword" => "on", "global" => false, "first" => 10}
        })

      assert %{
               "data" => %{
                 "searchGroupsPaginated" => %{
                   "edges" => [%{"node" => %{"name" => "second"}}]
                 }
               }
             } = json_response(response, 200)
    end

    test "can get live partners that user is a member of", %{
      conn: conn,
      partner3: partner3,
      user: user
    } do
      OmegaBravera.Groups.join_partner(partner3.id, user.id)

      response =
        post(conn, "/api", %{
          query: @search_groups,
          variables: %{"global" => false, "first" => 10, "myGroup" => true}
        })

      assert %{
               "data" => %{
                 "searchGroupsPaginated" => %{
                   "edges" => [%{"node" => %{"name" => "third"}}]
                 }
               }
             } = json_response(response, 200)
    end
  end
end
