defmodule OmegaBraveraWeb.NGOChalControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Trackers}

  @create_attrs %{
    "activity_type" => "Walk",
    "distance_target" => "100",
    "duration" => "20",
    "has_team" => "false",
    "money_target" => "500",
    "type" => "PER_MILESTONE"
  }
  @tracker_create_attrs %{
    email: "user@example.com",
    firstname: "some firstname",
    lastname: "some lastname",
    athlete_id: 123_456,
    token: "132kans81h23"
  }
  @invalid_attrs %{
    "activity_type" => "",
    "distance_target" => "",
    "duration" => "",
    "has_team" => "",
    "money_target" => "",
    "type" => ""
  }

  setup %{conn: conn} do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: "user@example.com",
      email_verified: true
    }

    with {:ok, user} <- Accounts.create_user(attrs),
         {:ok, _strava} = Trackers.create_strava(user.id, @tracker_create_attrs),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  @tag :authenticated
  test "new ngo_chal renders form", %{conn: conn} do
    ngo = insert(:ngo, %{url: "http://localhost:4000"})
    conn = get(conn, ngo_ngo_chal_path(conn, :new, ngo.slug))

    assert html_response(conn, 200) =~ "localhost"
  end

  describe "create ngo_chal" do
    test "redirects to show when data is valid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000"})
      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: @create_attrs)

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo.slug, slug)

      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo.slug, slug))
      assert html_response(conn, 200) =~ ngo.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000"})
      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: @invalid_attrs)
      assert html_response(conn, 200) =~ ngo.name
    end

    # TODO: add a positive and negative team test
  end

  describe "show ngo_chal" do
    setup do
      ngo_1 = insert(:ngo, %{slug: "ngo-1"})
      ngo_2 = insert(:ngo, %{slug: "ngo-2"})
      strava = insert(:strava)

      challenge_1 =
        insert(:ngo_challenge, %{
          ngo: ngo_1,
          default_currency: "hkd",
          user: strava.user
        })

      challenge_2 =
        insert(:ngo_challenge, %{
          ngo: ngo_2,
          default_currency: "myr",
          user: strava.user
        })

      {:ok, %{ngo_1: ngo_1, ngo_2: ngo_2, challenge_1: challenge_1, challenge_2: challenge_2}}
    end

    test "challenge 1 renders properly", %{conn: conn, challenge_1: challenge, ngo_1: ngo} do
      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo, challenge))

      assert html_response(conn, 200) =~ "HK$"
    end

    test "challenge 2 renders properly", %{conn: conn, challenge_2: challenge, ngo_2: ngo} do
      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo, challenge))

      assert html_response(conn, 200) =~ "RM"
    end
  end
end
