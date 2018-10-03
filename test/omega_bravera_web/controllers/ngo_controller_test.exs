defmodule OmegaBraveraWeb.NGOControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Fundraisers

  @create_attrs %{
    desc: "some desc",
    logo: "some logo",
    name: "some name",
    slug: "some slug",
    stripe_id: "some stripe_id"
  }
  @update_attrs %{
    desc: "some updated desc",
    logo: "some updated logo",
    name: "some updated name",
    slug: "some updated slug",
    stripe_id: "some updated stripe_id"
  }
  @invalid_attrs %{desc: nil, logo: nil, name: nil, slug: nil, stripe_id: nil}

  def fixture(:ngo) do
    {:ok, ngo} = Fundraisers.create_ngo(@create_attrs)
    ngo
  end

  @tag :skip
  describe "index" do
    test "lists all ngos", %{conn: conn} do
      conn = get(conn, ngo_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Ngos"
    end
  end

  @tag :skip
  describe "new ngo" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ngo_path(conn, :new))
      assert html_response(conn, 200) =~ "New Ngo"
    end
  end

  describe "create ngo" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ngo_path(conn, :create), ngo: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_path(conn, :show, id)

      conn = get(conn, ngo_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Ngo"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ngo_path(conn, :create), ngo: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Ngo"
    end
  end

  @tag :skip
  describe "edit ngo" do
    setup [:create_ngo]

    test "renders form for editing chosen ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, ngo_path(conn, :edit, ngo))
      assert html_response(conn, 200) =~ "Edit Ngo"
    end
  end

  describe "update ngo" do
    setup [:create_ngo]

    @tag :skip
    test "redirects when data is valid", %{conn: conn, ngo: ngo} do
      conn = put(conn, ngo_path(conn, :update, ngo), ngo: @update_attrs)
      assert redirected_to(conn) == ngo_path(conn, :show, ngo)

      conn = get(conn, ngo_path(conn, :show, ngo))
      assert html_response(conn, 200) =~ "some updated desc"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, ngo: ngo} do
      conn = put(conn, ngo_path(conn, :update, ngo), ngo: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Ngo"
    end
  end

  @tag :skip
  describe "delete ngo" do
    setup [:create_ngo]

    test "deletes chosen ngo", %{conn: conn, ngo: ngo} do
      conn = delete(conn, ngo_path(conn, :delete, ngo))
      assert redirected_to(conn) == ngo_path(conn, :index)

      assert_error_sent(404, fn ->
        get(conn, ngo_path(conn, :show, ngo))
      end)
    end
  end

  defp create_ngo(_) do
    ngo = fixture(:ngo)
    {:ok, ngo: ngo}
  end
end
