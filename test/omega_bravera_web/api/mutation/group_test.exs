defmodule OmegaBraveraWeb.Api.Mutation.GroupTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @vote_partner_mutation """
  mutation($partnerId: ID!) {
    votePartner(partnerId: $partnerId) {
      user {
        profilePicture
      }
    }
  }
  """

  @join_partner_mutation """
  mutation($partnerId: ID!) {
    joinPartner(partnerId: $partnerId) {
      id
    }
  }
  """

  @join_private_partner_mutation """
  mutation($partnerId: ID!, $password: String) {
    joinPartner(partnerId: $partnerId, password: $password) {
      id
    }
  }
  """

  @leave_group """
  mutation($groupId: ID!) {
    leaveGroup(groupId: $groupId) {
      id
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: "test@email.com"})
    credential = Fixtures.credential_fixture(user.id)
    partner = Fixtures.partner_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     partner: partner,
     user: user}
  end

  test "can vote for partner to have offers", %{conn: conn, partner: %{id: partner_id}} do
    response =
      post(conn, "/api", %{query: @vote_partner_mutation, variables: %{"partnerId" => partner_id}})

    assert %{"data" => %{"votePartner" => [_location]}} = json_response(response, 200)
  end

  test "can join partner", %{conn: conn, partner: %{id: partner_id}} do
    response =
      post(conn, "/api", %{query: @join_partner_mutation, variables: %{"partnerId" => partner_id}})

    string_partner_id = to_string(partner_id)

    assert %{"data" => %{"joinPartner" => %{"id" => ^string_partner_id}}} =
             json_response(response, 200)
  end

  test "can join a private partner", %{conn: conn, partner: partner} do
    {:ok, _partner} = OmegaBravera.Groups.update_partner(partner, %{join_password: "pass"})

    response =
      post(conn, "/api", %{
        query: @join_private_partner_mutation,
        variables: %{"partnerId" => partner.id, "password" => "pass"}
      })

    string_partner_id = to_string(partner.id)

    assert %{"data" => %{"joinPartner" => %{"id" => ^string_partner_id}}} =
             json_response(response, 200)
  end

  test "can join email restricted partner", %{conn: conn, partner: partner} do
    {:ok, _partner} =
      OmegaBravera.Groups.update_partner(partner, %{
        join_password: "pass",
        email_restriction: "Email.COM"
      })

    response =
      post(conn, "/api", %{
        query: @join_private_partner_mutation,
        variables: %{"partnerId" => partner.id, "password" => "pass"}
      })

    string_partner_id = to_string(partner.id)

    assert %{"data" => %{"joinPartner" => %{"id" => ^string_partner_id}}} =
             json_response(response, 200)
  end

  test "block user from joining partner if does not have the smae email suffix", %{
    conn: conn,
    partner: partner
  } do
    {:ok, _partner} =
      OmegaBravera.Groups.update_partner(partner, %{email_restriction: "gMaiL.Co "})

    response =
      post(conn, "/api", %{
        query: @join_private_partner_mutation,
        variables: %{"partnerId" => partner.id}
      })

    assert %{"errors" => [%{"message" => "This group is restricted to specific users."}]} =
             json_response(response, 200)
  end

  test "return error if the user tries to join a group again", %{
    conn: conn,
    partner: partner,
    user: user
  } do
    {:ok, partner} =
      OmegaBravera.Groups.update_partner(partner, %{
        join_password: "pass",
        email_restriction: "Email.COM"
      })

    OmegaBravera.Groups.join_partner(partner.id, user.id)

    response =
      post(conn, "/api", %{
        query: @join_private_partner_mutation,
        variables: %{"partnerId" => partner.id, "password" => "pass"}
      })

    assert %{"errors" => [%{"message" => "You have already joined this group."}]} =
             json_response(response, 200)
  end

  test "can leave group", %{conn: conn, partner: partner, user: user} do
    OmegaBravera.Groups.join_partner(partner.id, user.id)

    response =
      post(conn, "/api", %{
        query: @leave_group,
        variables: %{"groupId" => partner.id}
      })

    string_partner_id = to_string(partner.id)

    assert %{"data" => %{"leaveGroup" => %{"id" => ^string_partner_id}}} =
             json_response(response, 200)
  end
end
