defmodule OmegaBraveraWeb.NGOChalControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  @create_attrs %{
    activity: "some activity",
    distance_target: "120.5",
    duration: 42,
    money_target: "120.5",
    slug: "some slug",
    start_date: "2010-04-17 14:00:00.000000Z",
    status: "some status",
    type: "Per Goal"
  }
  @invalid_attrs %{
    activity: nil,
    distance_target: nil,
    duration: nil,
    money_target: nil,
    slug: nil,
    start_date: nil,
    status: nil,
    type: nil
  }

  @tag :authenticated
  test "new ngo_chal renders form", %{conn: conn} do
    ngo = insert(:ngo, %{url: "http://localhost:4000"})
    conn = get(conn, ngo_ngo_chal_path(conn, :new, ngo.slug))

    assert html_response(conn, 200) =~ "localhost"
  end

  describe "create ngo_chal" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ngo_ngo_chal_path(conn, :create, "foo"), ngo_chal: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo_slug: "foo", slug: "bar")

      conn = get(conn, ngo_ngo_chal_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Ngo chal"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ngo_ngo_chal_path(conn, :create, "foo"), ngo_chal: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Ngo chal"
    end
  end

  describe "show ngo_chal" do
    setup do
      ngo_1 = insert(:ngo, %{slug: "ngo-1"})
      ngo_2 = insert(:ngo, %{slug: "ngo-2"})
      slug = "random-123"
      strava = insert(:strava)

      challenge_1 =
        insert(:ngo_challenge, %{
          ngo: ngo_1,
          slug: slug,
          default_currency: "hkd",
          user: strava.user
        })

      challenge_2 =
        insert(:ngo_challenge, %{
          ngo: ngo_2,
          slug: slug,
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
