defmodule OmegaBraveraWeb.DonationControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  @create_attrs %{amount: "120.5", currency: "some currency", milestone: 42, status: "some status", str_src: "some str_src"}
  @invalid_attrs %{amount: nil, currency: nil, milestone: nil, status: nil, str_src: nil}

  describe "create donation" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_donation_path(conn, :create, "foo", "bar"), donation: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, "foo", "bar")
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_donation_path(conn, :create, "foo", "bar"), donation: @invalid_attrs
      assert html_response(conn, 200) =~ "New Donation"
    end
  end
end
