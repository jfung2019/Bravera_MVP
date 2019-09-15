defmodule OmegaBraveraWeb.Api.Mutation.ActivityTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}
  alias OmegaBraveraWeb.Api.Auth

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation($distance: Decimal!, $start_date: Date!, $end_date: Date!, $source: String!) {
   createActivity(input: {distance: $distance, startDate: $start_date, endDate: $end_date, source: $source}) {
    	activity{
        id
        distance
        startDate
        endDate
        source
      }
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

  test "api/create_activity can create activity" do
    credential = credential_fixture()
    device = insert(:device, %{active: true, user_id: credential.user_id})

    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    device_token = Auth.generate_device_token(device.uuid)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{auth_token}")
      |> put_req_header("device", "Device #{device_token}")

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
            "source" => "bravera"
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

  test "api/create_activity will refuse duplicate activities based on start and end dates" do
    credential = credential_fixture()
    device = insert(:device, %{active: true, user_id: credential.user_id})

    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    device_token = Auth.generate_device_token(device.uuid)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{auth_token}")
      |> put_req_header("device", "Device #{device_token}")

    post(
      conn,
      "/api",
      %{
        query: @query,
        variables: %{
          "distance" => "10.7",
          "start_date" => "2019-08-06T14:54:54+00:00",
          "end_date" => "2019-08-06T16:54:54+00:00",
          "source" => "bravera"
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
            "source" => "bravera"
          }
        }
      )

    assert %{
             "data" => %{"createActivity" => nil},
             "errors" => [
               %{
                 "details" => %{"id" => ["Duplicate activity"]},
                 "locations" => [%{"column" => 0, "line" => 2}],
                 "message" => "Could not create activity",
                 "path" => ["createActivity"]
               }
             ]
           } = json_response(response, 200)
  end

  test "api/create_activity requires device token to be present in request" do
    credential = credential_fixture()
    _device = insert(:device, %{active: true, user_id: credential.user_id})

    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{auth_token}")

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
            "source" => "bravera"
          }
        }
      )

    assert %{
             "data" => %{"createActivity" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 2}],
                 "message" => "Device token expired or non-existent",
                 "path" => ["createActivity"]
               }
             ]
           } = json_response(response, 200)
  end
end
