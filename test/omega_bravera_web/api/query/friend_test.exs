defmodule OmegaBraveraWeb.Api.Query.FriendTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Fixtures}

  @list_friends """
  query($keyword: String, $first: Integer!) {
    listFriends(keyword: $keyword, first: $first) {
      edges {
        node {
          id
          username
          total_points
        }
      }
      pageInfo {
        hasNextPage
        startCursor
        endCursor
      }
    }
  }
  """

  @list_friend_requests """
  query {
    listFriendRequests {
      requester {
        id
        username
        firstname
        lastname
      }
      status
    }
  }
  """

  @list_possible_friends """
  query($keyword: String, $first: Integer!) {
    listPossibleFriends(keyword: $keyword, first: $first) {
      edges {
        node {
          id
          username
          friendStatus
        }
      }
      pageInfo {
        hasNextPage
        startCursor
        endCursor
      }
    }
  }
  """

  @compare_with_friend """
  query($friendUserId: ID!) {
    compareWithFriend(friendUserId: $friendUserId) {
      user {
        id
        username
        profilePicture
        totalKilometersToday
        totalKilometersThisWeek
        totalKilometersThisMonth
        totalPoints
        insertedAt
        groups {
          name
        }
      }
      friend {
        id
        username
        profilePicture
        totalKilometersToday
        totalKilometersThisWeek
        totalKilometersThisMonth
        totalPoints
        insertedAt
        groups {
          name
        }
      }
    }
  }
  """

  setup %{conn: conn} do
    user1 = insert(:user)
    user2 = insert(:user, %{email: "user2@email.com"})
    user3 = insert(:user, %{email: "user3@email.com", username: "z"})
    credential = Fixtures.credential_fixture(user1.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     user1: user1,
     user2: user2,
     user3: user3}
  end

  test "can list friends", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    {:ok, friend} =
      Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    Accounts.accept_friend_request(friend)

    response = post(conn, "/api", %{query: @list_friends, variables: %{"first" => 3}})

    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "listFriends" => %{
                 "edges" => [%{"node" => %{"id" => ^user2_id_string}}]
               }
             }
           } = json_response(response, 200)
  end

  test "can list friend requests", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    response =
      post(conn, "/api", %{query: @list_friend_requests, variables: %{"requesterId" => user2_id}})

    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "listFriendRequests" => [
                 %{
                   "requester" => %{"id" => ^user2_id_string},
                   "status" => "PENDING"
                 }
               ]
             }
           } = json_response(response, 200)
  end

  test "can list possible users for sending friend request", %{
    conn: conn,
    user2: %{id: user2_id},
    user3: %{id: user3_id}
  } do
    Accounts.create_friend_request(%{receiver_id: user3_id, requester_id: user2_id})

    response = post(conn, "/api", %{query: @list_possible_friends, variables: %{"first" => 3}})

    user2_id_string = to_string(user2_id)
    user3_id_string = to_string(user3_id)

    assert %{
             "data" => %{
               "listPossibleFriends" => %{
                 "edges" => [
                   %{"node" => %{"id" => ^user2_id_string, "friendStatus" => "stranger"}},
                   %{"node" => %{"id" => ^user3_id_string, "friendStatus" => "stranger"}}
                 ]
               }
             }
           } = json_response(response, 200)
  end

  test "can list possible users and show that a request was created", %{
    conn: conn,
    user1: %{id: user1_id},
    user2: %{id: user2_id},
    user3: %{id: user3_id}
  } do
    Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    {:ok, friend} =
      Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user3_id})

    Accounts.accept_friend_request(friend)

    response = post(conn, "/api", %{query: @list_possible_friends, variables: %{"first" => 3}})

    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "listPossibleFriends" => %{
                 "edges" => [
                   %{"node" => %{"id" => ^user2_id_string, "friendStatus" => "pending"}}
                 ]
               }
             }
           } = json_response(response, 200)
  end

  test "can compare with friend", %{conn: conn, user1: %{id: user1_id}, user2: %{id: user2_id}} do
    {:ok, friend} =
      Accounts.create_friend_request(%{receiver_id: user1_id, requester_id: user2_id})

    Accounts.accept_friend_request(friend)

    response =
      post(conn, "/api", %{query: @compare_with_friend, variables: %{"friendUserId" => user2_id}})

    user1_id_string = to_string(user1_id)
    user2_id_string = to_string(user2_id)

    assert %{
             "data" => %{
               "compareWithFriend" => %{
                 "friend" => %{"id" => ^user2_id_string},
                 "user" => %{"id" => ^user1_id_string}
               }
             }
           } = json_response(response, 200)
  end

  test "cannot compare with user if not friend", %{conn: conn, user2: %{id: user2_id}} do
    response =
      post(conn, "/api", %{query: @compare_with_friend, variables: %{"friendUserId" => user2_id}})

    assert %{"errors" => [%{"message" => "It seems you are not a friend with this user."}]} =
             json_response(response, 200)
  end
end
