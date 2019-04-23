defmodule OmegaBraveraWeb.OfferChallengeControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Offers, Accounts}

  @tracker_create_attrs %{
    email: "user@example.com",
    firstname: "some firstname",
    lastname: "some lastname",
    athlete_id: 123_456,
    token: "132kans81h23"
  }

  setup %{conn: conn} do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: nil,
      email_verified: false
    }

    with {:ok, user} <- OmegaBravera.Accounts.create_user(attrs),
         {:ok, _strava} = OmegaBravera.Trackers.create_strava(user.id, @tracker_create_attrs),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
            current_user: user}
  end

  describe "create" do
    test "create/2 refuses to create challenge if offer end date was reached", %{
      conn: conn,
      current_user: user
    } do
      {:ok, _user} =
        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})

      offer =
        insert(:offer, %{start_date: Timex.now(), end_date: Timex.shift(Timex.now(), days: -5)})

      conn =
        post(
          conn,
          offer_offer_challenge_path(conn, :create, offer.slug)
        )

      assert get_flash(conn, :error) == "Could not create offer challenge."
      assert Offers.list_offer_challenges() == []
    end

    test "create/2 redirects to challenge data is valid", %{conn: conn, current_user: user} do
      {:ok, _user} =
        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})

      offer =
        insert(:offer, %{start_date: Timex.now(), end_date: Timex.shift(Timex.now(), days: 10)})

      conn =
        post(
          conn,
          offer_offer_challenge_path(conn, :create, offer.slug)
        )

      assert get_flash(conn, :info) == "Success! You have registered for this offer!"
      assert [challenge] = Offers.list_offer_challenges()
      assert redirected_to(conn) == offer_offer_challenge_path(conn, :show, offer, challenge)
    end
  end

  test "unverified user should get their session saved with where to go when they verify email",
       %{conn: conn, current_user: _user} do
    offer = insert(:offer, %{slug: "sherief-1"})

    conn = get(conn, offer_offer_challenge_path(conn, :new, offer))
    assert html_response(conn, 200) =~ "verify your email address"

    assert Plug.Conn.get_session(conn, :after_email_verify) ==
             offer_offer_challenge_path(conn, :new, offer)
  end

  describe "redeem" do
    test "new_redeem/2 renders redeem form for vendor", %{conn: conn} do
      offer_redeem = insert(:offer_redeem)

      conn =
        get(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :new_redeem,
            offer_redeem.offer.slug,
            offer_redeem.offer_challenge.slug,
            offer_redeem.token
          )
        )

      assert html_response(conn, 200) =~ "New Redemption"
    end

    test "save_redeem/2 updates a redeem when valid data is given", %{conn: conn} do
      offer_redeem = insert(:offer_redeem)

      params = %{vendor_id: offer_redeem.vendor.vendor_id, offer_reward_id: offer_redeem.offer_reward.id}

      conn =
        post(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :save_redeem,
            offer_redeem.offer.slug,
            offer_redeem.offer_challenge.slug,
            offer_redeem.token
          ),
          offer_redeem: params
        )

      assert html = html_response(conn, 200)
      assert html =~ "Confirmed!"
      assert html =~ "Total Redemptions to date:</span>\n        <span><b>2"

      offer_redeemed_ = Offers.get_offer_redeems!(offer_redeem.id)
      assert offer_redeemed_.status == "redeemed"
    end

    test "save_redeem/2 renders errors when invalid data is given", %{conn: conn} do
      offer_redeem = insert(:offer_redeem)

      params = %{vendor_id: "", offer_reward_id: offer_redeem.offer_reward.id}

      conn =
        post(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :save_redeem,
            offer_redeem.offer.slug,
            offer_redeem.offer_challenge.slug,
            offer_redeem.token
          ),
          offer_redeem: params
        )

      assert html_response(conn, 200) =~ "Your Vendor ID seems to be incorrect."

      offer = Offers.get_offer_by_slug(offer_redeem.offer.slug, [:offer_redeems])
      assert length(offer.offer_redeems) == 1
      offer_redeemed_ = Offers.get_offer_redeems!(offer_redeem.id)
      assert offer_redeemed_.status == "pending"
    end
  end
end
