defmodule OmegaBraveraWeb.NGOChalControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Challenges

  @create_attrs %{activity: "some activity", distance_target: "120.5", duration: 42, money_target: "120.5", slug: "some slug", start_date: "2010-04-17 14:00:00.000000Z", status: "some status"}
  @update_attrs %{activity: "some updated activity", distance_target: "456.7", duration: 43, money_target: "456.7", slug: "some updated slug", start_date: "2011-05-18 15:01:01.000000Z", status: "some updated status"}
  @invalid_attrs %{activity: nil, distance_target: nil, duration: nil, money_target: nil, slug: nil, start_date: nil, status: nil}

  def fixture(:ngo_chal) do
    {:ok, ngo_chal} = Challenges.create_ngo_chal(@create_attrs)
    ngo_chal
  end

  describe "new ngo_chal" do
    test "renders form", %{conn: conn} do
      conn = get conn, ngo_ngo_chal_path(conn, :new, slug: "foo")
      assert html_response(conn, 200) =~ "New Ngo chal"
    end
  end

  describe "create ngo_chal" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_path(conn, :create, ngo_slug: "foo"), ngo_chal: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo_slug: "foo", slug: "bar")

      conn = get conn, ngo_ngo_chal_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Ngo chal"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_path(conn, :create, ngo_slug: "foo"), ngo_chal: @invalid_attrs
      assert html_response(conn, 200) =~ "New Ngo chal"
    end
  end

  describe "edit ngo_chal" do
    setup [:create_ngo_chal]

    test "renders form for editing chosen ngo_chal", %{conn: conn, ngo_chal: ngo_chal} do
      conn = get conn, ngo_ngo_chal_path(conn, :edit, ngo_chal)
      assert html_response(conn, 200) =~ "Edit Ngo chal"
    end
  end

  describe "update ngo_chal" do
    setup [:create_ngo_chal]

    test "redirects when data is valid", %{conn: conn, ngo_chal: ngo_chal} do
      conn = put conn, ngo_ngo_chal_path(conn, :update, ngo_chal), ngo_chal: @update_attrs
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo_chal)

      conn = get conn, ngo_ngo_chal_path(conn, :show, ngo_chal)
      assert html_response(conn, 200) =~ "some updated activity"
    end

    test "renders errors when data is invalid", %{conn: conn, ngo_chal: ngo_chal} do
      conn = put conn, ngo_ngo_chal_path(conn, :update, ngo_chal), ngo_chal: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Ngo chal"
    end
  end

  defp create_ngo_chal(_) do
    ngo_chal = fixture(:ngo_chal)
    {:ok, ngo_chal: ngo_chal}
  end
end
