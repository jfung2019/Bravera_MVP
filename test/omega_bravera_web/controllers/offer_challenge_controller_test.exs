defmodule OmegaBraveraWeb.OfferChallengeControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Offers

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
      offer_challenge = insert(:offer_challenge)

      conn =
        get(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :new_redeem,
            offer_challenge.offer.slug,
            offer_challenge.slug,
            offer_challenge.redeem_token
          )
        )

      assert html_response(conn, 200) =~ "New Redeem"
    end

    test "save_redeem/2 creates a redeem when valid data is given", %{conn: conn} do
      vendor = insert(:vendor)
      offer = insert(:offer, vendor: nil, vendor_id: vendor.vendor_id)
      offer_challenge = insert(:offer_challenge, offer: nil, offer_id: offer.id)
      offer_reward = insert(:offer_reward, offer: nil, offer_id: offer.id)

      params = %{vendor_id: vendor.vendor_id, offer_reward_id: offer_reward.id}

      conn =
        post(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :save_redeem,
            offer.slug,
            offer_challenge.slug,
            offer_challenge.redeem_token
          ),
          offer_redeem: params
        )

      assert html_response(conn, 200) =~ "Redeem Confirmed!"

      offer = Offers.get_offer_by_slug(offer.slug, [:offer_redeems])
      assert length(offer.offer_redeems) == 1
    end

    test "save_redeem/2 renders errors when invalid data is given", %{conn: conn} do
      vendor = insert(:vendor)
      offer = insert(:offer, vendor: nil, vendor_id: vendor.vendor_id)
      offer_challenge = insert(:offer_challenge, offer: nil, offer_id: offer.id)
      offer_reward = insert(:offer_reward, offer: nil, offer_id: offer.id)

      params = %{vendor_id: "", offer_reward_id: offer_reward.id}

      conn =
        post(
          conn,
          offer_offer_challenge_offer_challenge_path(
            conn,
            :save_redeem,
            offer.slug,
            offer_challenge.slug,
            offer_challenge.redeem_token
          ),
          offer_redeem: params
        )

      assert get_flash(conn, :error) == "Your Vendor ID seems to be incorrect."

      offer = Offers.get_offer_by_slug(offer.slug, [:offer_redeems])
      assert length(offer.offer_redeems) == 0
    end
  end
end
