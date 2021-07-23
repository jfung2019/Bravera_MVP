defmodule OmegaBraveraWeb.Api.Query.PointsTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @points_balance_query """
    query {
      userPointsHistory {
        balance
        history {
          posValue
          negValue
          distance
          insertedAt
          updatedAt
        }
      }
    }
  """

  @points_breakdown_query """
  query($day: Day!) {
    userPointDayBreakdown(day: $day) {
      value
      source
      insertedAt
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     user: credential.user, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "can get points balance from current user", %{conn: conn} do
    response = post(conn, "/api", %{query: @points_balance_query})

    assert %{"data" => %{"userPointsHistory" => %{"balance" => 0.0, "history" => []}}} =
             json_response(response, 200)
  end

  test "can get points breakdown from a day", %{conn: conn} do
    response =
      post(conn, "/api", %{query: @points_breakdown_query, variables: %{"day" => "2020-03-09"}})

    assert %{"data" => %{"userPointDayBreakdown" => []}} = json_response(response, 200)
  end
end
