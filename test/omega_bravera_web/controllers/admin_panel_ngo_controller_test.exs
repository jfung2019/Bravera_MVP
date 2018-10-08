defmodule OmegaBraveraWeb.Admin.NGOControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts
  alias OmegaBravera.Fundraisers

  @ngo_create_attrs %{
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

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:ngo) do
    {:ok, ngo} = Fundraisers.create_ngo(@ngo_create_attrs)
    ngo
  end

  describe "index" do
    setup [:create_ngo]

    test "lists all ngos in admin panel", %{conn: conn} do
      conn = get(conn, admin_panel_ngo_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing NGOs"
    end
  end

  describe "show" do
    setup [:create_ngo]

    test "shows a specific ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, admin_panel_ngo_path(conn, :show, ngo))
      assert html_response(conn, 200) =~ "Challenges:"
    end
  end

  describe "new ngo" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_panel_ngo_path(conn, :new))
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "create ngo" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, admin_panel_ngo_path(conn, :create), ngo: @ngo_create_attrs)
      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == admin_panel_ngo_path(conn, :show, slug)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_panel_ngo_path(conn, :create), ngo: %{name: "foo name"})
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "edit ngo" do
    setup [:create_ngo]

    test "renders form for editing chosen ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, admin_panel_ngo_path(conn, :edit, ngo))
      assert html_response(conn, 200)
    end
  end

  describe "update ngo" do
    setup [:create_ngo]

    test "redirects when data is valid after updating", %{conn: conn, ngo: ngo} do
      conn = put(conn, admin_panel_ngo_path(conn, :update, ngo), ngo: @update_attrs)
      assert redirected_to(conn) == admin_panel_ngo_path(conn, :index)
    end

    test "renders errors in update when data is invalid", %{conn: conn, ngo: ngo} do
      conn = put(conn, admin_panel_ngo_path(conn, :update, ngo), ngo: %{name: nil})
      assert html_response(conn, 200)
    end
  end

  defp create_ngo(_) do
    ngo = fixture(:ngo)
    {:ok, ngo: ngo}
  end
end
