defmodule OmegaBraveraWeb.Api.Mutation.FriendTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Fixtures}

  @create_friend_request """
  mutation($receiverId: ID!) {
    createFriendRequest(receiverId: $receiverId) {
      receiver {
        id
        username
      }
      requester {
        id
        username
      }
      status
    }
  }
  """

  @accept_friend_request """
  mutation($requesterId: ID!) {
    acceptFriendRequest(requesterId: $requesterId) {
      receiver {
        id
        username
      }
      requester {
        id
        username
      }
      status
    }
  }
  """

  @reject_friend_request """
  mutation($requesterId: ID!) {
    rejectFriendRequest(requesterId: $requesterId) {
      receiver {
        id
        username
      }
      requester {
        id
        username
      }
    }
  }
  """

  setup %{conn: conn} do
    user1 = insert(:user)
    user2 = insert(:user, %{email: "user2@email.com"})
    credential = Fixtures.credential_fixture(user1.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     user1: user1,
     user2: user2}
  end

  test "can create friend requests", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    response =
      post(conn, "/api", %{query: @create_friend_request, variables: %{"receiverId" => user2_id}})

    user1_id_string = to_string(user1_id)
    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "createFriendRequest" => %{
                 "receiver" => %{"id" => ^user2_id_string},
                 "requester" => %{"id" => ^user1_id_string},
                 "status" => "PENDING"
               }
             }
           } = json_response(response, 200)
  end

  test "can't create friend requests twice", %{
    conn: conn,
    user1: %{id: user1_id},
    user2: %{id: user2_id}
  } do
    Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    response =
      post(conn, "/api", %{query: @create_friend_request, variables: %{"receiverId" => user2_id}})

    user1_id_string = to_string(user1_id)
    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "createFriendRequest" => %{
                 "receiver" => %{"id" => ^user1_id_string},
                 "requester" => %{"id" => ^user2_id_string},
                 "status" => "PENDING"
               }
             }
           } = json_response(response, 200)
  end

  test "can accept friend request", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    response =
      post(conn, "/api", %{query: @accept_friend_request, variables: %{"requesterId" => user2_id}})

    user1_id_string = to_string(user1_id)
    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "acceptFriendRequest" => %{
                 "receiver" => %{"id" => ^user1_id_string},
                 "requester" => %{"id" => ^user2_id_string},
                 "status" => "ACCEPTED"
               }
             }
           } = json_response(response, 200)
  end

  test "can reject friend request", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    response =
      post(conn, "/api", %{query: @reject_friend_request, variables: %{"requesterId" => user2_id}})

    user1_id_string = to_string(user1_id)
    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "rejectFriendRequest" => %{
                 "receiver" => %{"id" => ^user1_id_string},
                 "requester" => %{"id" => ^user2_id_string}
               }
             }
           } = json_response(response, 200)
  end
end