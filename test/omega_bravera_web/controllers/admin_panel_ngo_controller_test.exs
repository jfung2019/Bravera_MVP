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

  defp create_ngo(_) do
    ngo = fixture(:ngo)
    {:ok, ngo: ngo}
  end

end
