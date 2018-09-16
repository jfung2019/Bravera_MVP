defmodule OmegaBraveraWeb.NGOChalControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Challenges
  import OmegaBravera.Factory
  import OmegaBravera.Guardian

  @create_attrs %{activity: "some activity", distance_target: "120.5", duration: 42, money_target: "120.5", slug: "some slug", start_date: "2010-04-17 14:00:00.000000Z", status: "some status"}
  @invalid_attrs %{activity: nil, distance_target: nil, duration: nil, money_target: nil, slug: nil, start_date: nil, status: nil}

  @tag :authenticated
  test "new ngo_chal renders form", %{conn: conn} do
    ngo = insert(:ngo, %{url: "http://localhost:4000"})
    conn = get(conn, ngo_ngo_chal_path(conn, :new, ngo.slug))

    assert html_response(conn, 200) =~ "Configure your Challenge"
  end

  describe "create ngo_chal" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_path(conn, :create, "foo"), ngo_chal: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo_slug: "foo", slug: "bar")

      conn = get conn, ngo_ngo_chal_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Ngo chal"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_path(conn, :create, "foo"), ngo_chal: @invalid_attrs
      assert html_response(conn, 200) =~ "New Ngo chal"
    end
  end
end
