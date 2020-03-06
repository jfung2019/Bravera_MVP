defmodule OmegaBraveraWeb.Api.Subscription.PointsTest do
  use OmegaBraveraWeb.SubscriptionCase
  import OmegaBravera.Factory

  @subscription """
  subscription {
    livePoints {
      balance
      history {
        source
      }
    }
  }
  """
  @mutation """
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

  test "can get update about points when points are created", %{socket: socket} do
    user = insert(:user)
    device = insert(:device, user: user)

    socket =
      Absinthe.Phoenix.Socket.put_options(socket,
        context: %{current_user: user, device: device}
      )

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)
    # setup a subscription
    ref = push_doc(socket, @subscription)
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    # run a mutation to trigger the subscription
    now = Timex.now()

    {:ok, now_string} =
      now |> Timex.shift(minutes: 2) |> Timex.format("{YYYY}-{0M}-{0D}T{h24}:{m}{Z:}")

    end_date = now |> Timex.shift(minutes: 30)
    {:ok, end_date_string} = end_date |> Timex.format("{YYYY}-{0M}-{0D}T{h24}:{m}{Z:}")

    ref =
      push_doc(socket, @mutation,
        variables: %{
          "distance" => "10.7",
          "start_date" => now_string,
          "end_date" => end_date_string,
          "source" => "bravera",
          "type" => "Walk"
        }
      )

    assert_reply ref, :ok, reply
    assert %{data: %{"createActivity" => %{"activity" => %{"id" => _id}}}} = reply

    # check to see if we got subscription data
    expected = %{
      result: %{
        data: %{"livePoints" => %{"balance" => 80.0, "history" => [%{"source" => nil}]}}
      },
      subscriptionId: subscription_id
    }

    assert_push "subscription:data", push
    assert expected == push
  end

end