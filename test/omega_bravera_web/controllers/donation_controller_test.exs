defmodule OmegaBraveraWeb.DonationControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Money

  @create_attrs %{amount: "120.5", currency: "some currency", milestone: 42, status: "some status", str_src: "some str_src"}
  @update_attrs %{amount: "456.7", currency: "some updated currency", milestone: 43, status: "some updated status", str_src: "some updated str_src"}
  @invalid_attrs %{amount: nil, currency: nil, milestone: nil, status: nil, str_src: nil}

  def fixture(:donation) do
    {:ok, donation} = Money.create_donation(@create_attrs)
    donation
  end

  describe "new donation" do
    test "renders form", %{conn: conn} do
      conn = get conn, ngo_ngo_chal_donation_path(conn, :new, "foo", "bar")
      assert html_response(conn, 200) =~ "New Donation"
    end
  end

  describe "create donation" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_donation_path(conn, :create, "foo", "bar"), donation: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_donation_path(conn, :show, "foo", "bar")

      conn = get conn, ngo_ngo_chal_donation_path(conn, :show, "foo", "bar", id)
      assert html_response(conn, 200) =~ "Show Donation"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, ngo_ngo_chal_donation_path(conn, :create, "foo", "bar"), donation: @invalid_attrs
      assert html_response(conn, 200) =~ "New Donation"
    end
  end

  defp create_donation(_) do
    donation = fixture(:donation)
    {:ok, donation: donation}
  end
end
