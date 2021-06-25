defmodule OmegaBraveraWeb.Api.Mutation.ActivityTest do
  use OmegaBraveraWeb.ConnCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}
  alias OmegaBraveraWeb.Api.Auth

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation($distance: Decimal!, $start_date: Date!, $end_date: Date!, $source: String!, $type: String!) {
   createActivity(input: {distance: $distance, startDate: $start_date, endDate: $end_date, source: $source, type: $type}) {
    	activity{
        id
        distance
        startDate
        endDate
        source
        type
      }
    }
  }
  """

  @create_pedometer_activity """
  mutation($stepCount: Integer!, $startDate: Date!) {
    createPedometerActivity(stepCount: $stepCount, startDate: $startDate) {
      id
      stepCount
      distance
      startDate
      source
      type
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

    credential |> Repo.preload(:user)
  end

  setup do
    credential = credential_fixture()
    device = insert(:device, %{active: true, user_id: credential.user_id})
    token = Auth.generate_device_token(device.uuid)
    {:ok, user_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, token: token, user_token: user_token}
  end

  test "api/create_activity can create activity", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")

    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "distance" => "10.7",
            "start_date" => "2019-08-06T14:54:54+00:00",
            "end_date" => "2019-08-06T16:54:54+00:00",
            "source" => "bravera",
            "type" => "Walk"
          }
        }
      )

    assert %{
             "data" => %{
               "createActivity" => %{
                 "activity" => %{
                   "distance" => 10.7,
                   "source" => "bravera"
                 }
               }
             }
           } = json_response(response, 200)
  end

  test "api/create_activity will not accept banned sources", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")

    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "distance" => "10.7",
            "start_date" => "2019-08-06T14:54:54+00:00",
            "end_date" => "2019-08-06T16:54:54+00:00",
            "source" => "Connect",
            "type" => "Walk"
          }
        }
      )

    assert %{
             "data" => %{"createActivity" => nil},
             "errors" => [
               %{
                 "details" => %{"source" => ["Connect is not allowed."]},
                 "locations" => [%{"column" => _, "line" => _}],
                 "message" => "Could not create activity",
                 "path" => ["createActivity"]
               }
             ]
           } = json_response(response, 200)
  end

  test "api/create_activity will refuse duplicate activities based on start and end dates", %{
    token: token
  } do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")

    post(
      conn,
      "/api",
      %{
        query: @query,
        variables: %{
          "distance" => "10.7",
          "start_date" => "2019-08-06T14:54:54+00:00",
          "end_date" => "2019-08-06T16:54:54+00:00",
          "source" => "bravera",
          "type" => "Walk"
        }
      }
    )

    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "distance" => "10.7",
            "start_date" => "2019-08-06T14:54:54+00:00",
            "end_date" => "2019-08-06T16:54:54+00:00",
            "source" => "bravera",
            "type" => "Run"
          }
        }
      )

    assert %{
             "data" => %{"createActivity" => nil},
             "errors" => [
               %{
                 "details" => %{"id" => ["Duplicate activity"]},
                 "locations" => [%{"column" => _, "line" => _}],
                 "message" => "Could not create activity",
                 "path" => ["createActivity"]
               }
             ]
           } = json_response(response, 200)
  end

  test "api/create_activity requires device token to be present in request", %{
    user_token: user_token
  } do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{user_token}")

    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "distance" => "10.7",
            "start_date" => "2019-08-06T14:54:54+00:00",
            "end_date" => "2019-08-06T16:54:54+00:00",
            "source" => "bravera",
            "type" => "Walk"
          }
        }
      )

    assert %{
             "data" => %{"createActivity" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => _, "line" => _}],
                 "message" => "Device token expired or non-existent",
                 "path" => ["createActivity"]
               }
             ]
           } = json_response(response, 200)
  end

  test "can create pedometer activity", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")

    now =
      Timex.now()
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    response =
      post(conn, "/api", %{
        query: @create_pedometer_activity,
        variables: %{"stepCount" => 10, "startDate" => now}
      })

    distance = Float.round(10 / 1350, 3)

    assert %{
             "data" => %{
               "createPedometerActivity" => %{
                 "distance" => ^distance,
                 "source" => "bravera_pedometer",
                 "startDate" => ^now,
                 "stepCount" => 10,
                 "type" => "Walk"
               }
             }
           } = json_response(response, 200)
  end
end
