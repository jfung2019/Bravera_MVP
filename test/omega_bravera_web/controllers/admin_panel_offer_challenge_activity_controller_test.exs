defmodule OmegaBraveraWeb.Admin.OfferChallengeActivityControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Accounts

  @activity_create_attrs %{
    "start_date" => %{
      # Must be in the future so that ActivityIngestion doesn't refuse it
      "hour" => Integer.to_string(Timex.shift(Timex.now("Asia/Hong_Kong"), hours: 5).hour),
      "minute" => Integer.to_string(Timex.shift(Timex.now("Asia/Hong_Kong"), hours: 5).minute),
      "year" => Integer.to_string(Timex.shift(Timex.now("Asia/Hong_Kong"), hours: 5).year),
      "month" => Integer.to_string(Timex.shift(Timex.now("Asia/Hong_Kong"), hours: 5).month),
      "day" => Integer.to_string(Timex.shift(Timex.now("Asia/Hong_Kong"), hours: 5).day)
    },
    "distance" => "30",
    "moving_time" => %{"hour" => "1", "minute" => "0", "second" => "0"},
    "average_speed" => "",
    # Filled in inside each test (challenge.activity_type)
    "type" => "",
    # If left blank then the Strava API call should be mocked (need athlete weight)
    "calories" => "300"
  }

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:challenge) do
    user = insert(:user)
    offer = insert(:offer, %{slug: "sherief-1"})

    challenge =
      insert(:offer_challenge, %{
        offer: offer,
        user: user,
        distance_target: 150,
        type: "PER_KM"
      })

    challenge
  end

  defp create_challenge(_) do
    challenge = fixture(:challenge)
    {:ok, challenge: challenge}
  end

  describe "new/2" do
    setup [:create_challenge]

    test "renders create activity form", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_offer_challenge_activity_path(conn, :new))
      assert html_response(conn, 200) =~ "New Offer Activity"
    end
  end

  describe "create/2" do
    setup [:create_challenge]

    test "redirects to index when data is valid", %{conn: conn, challenge: challenge} do
      conn =
        post(
          conn,
          Routes.admin_panel_offer_challenge_activity_path(conn, :create),
          activity_accumulator: %{@activity_create_attrs | "type" => challenge.activity_type},
          challenge_id: challenge.id
        )

      assert redirected_to(conn) == Routes.admin_panel_offer_path(conn, :online)
      assert get_flash(conn, :info) =~ "Activity created successfully."
    end

    test "redirects to index when activity data is refused by AcivityIngestion with an error flash",
         %{conn: conn, challenge: challenge} do
      past_time = Timex.now("Asia/Hong_Kong") |> Timex.shift(years: -2)

      conn =
        post(
          conn,
          Routes.admin_panel_offer_challenge_activity_path(conn, :create),
          activity_accumulator: %{
            @activity_create_attrs
            | "type" => challenge.activity_type,
              "start_date" => %{
                # Must be in the furture so that ActivityIngestion doesn't refuse it
                "hour" => Integer.to_string(past_time.hour),
                "minute" => "00",
                "year" => Integer.to_string(past_time.year),
                "month" => Integer.to_string(past_time.month),
                "day" => Integer.to_string(past_time.day)
              }
          },
          challenge_id: challenge.id
        )

      assert redirected_to(conn) == Routes.admin_panel_offer_path(conn, :online)
      assert get_flash(conn, :error) =~ "Activity not processed. Please check the logs."
    end
  end
end
