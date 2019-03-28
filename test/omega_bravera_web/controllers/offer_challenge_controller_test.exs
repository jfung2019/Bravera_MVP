defmodule OmegaBraveraWeb.OfferChallengeControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

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
       %{conn: conn, current_user: user} do
    offer = insert(:offer, %{slug: "sherief-1"})

    conn = get(conn, offer_offer_challenge_path(conn, :new, offer))
    assert html_response(conn, 200) =~ "verify your email address"

    assert Plug.Conn.get_session(conn, :after_email_verify) ==
             offer_offer_challenge_path(conn, :new, offer)
  end
end
