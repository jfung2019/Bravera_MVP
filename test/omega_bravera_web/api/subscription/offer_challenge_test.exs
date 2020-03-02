defmodule OmegaBraveraWeb.Api.Subscription.OfferChallengeTest do
  use OmegaBraveraWeb.SubscriptionCase
  import OmegaBravera.Factory

  @subscription """
  subscription {
    liveChallenges {
      id
      distance_covered
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
  @join_challenge_mutation """
  mutation($offerSlug: String!){
    earnOfferChallenge(offerSlug: $offerSlug){
      offerChallenge{
        id
      }
    }
  }
  """

  test "new activities can update live challenges", %{socket: socket} do
    challenge = insert(:offer_challenge)
    device = insert(:device, %{user_id: challenge.user_id, active: true})

    socket =
      Absinthe.Phoenix.Socket.put_options(socket,
        context: %{current_user: challenge.user, device: device}
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
        data: %{"liveChallenges" => [%{"id" => challenge.id, "distance_covered" => 10.7}]}
      },
      subscriptionId: subscription_id
    }

    assert_push "subscription:data", push
    assert expected == push
  end

  test "can create challenge and be notified of new challenge", %{socket: socket} do
    offer = insert(:offer)
    user = insert(:user)

    socket =
      Absinthe.Phoenix.Socket.put_options(socket,
        context: %{current_user: user, device: nil}
      )

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)
    # setup a subscription
    ref = push_doc(socket, @subscription)
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    ref = push_doc(socket, @join_challenge_mutation, variables: %{"offerSlug" => offer.slug})

    assert_reply ref, :ok, reply

    assert %{data: %{"earnOfferChallenge" => %{"offerChallenge" => %{"id" => challenge_id}}}} =
             reply

    # check to see if we got subscription data
    expected = %{
      result: %{
        data: %{"liveChallenges" => [%{"id" => challenge_id, "distance_covered" => 0.0}]}
      },
      subscriptionId: subscription_id
    }

    assert_push "subscription:data", push, 9999
    assert expected == push
  end
end
