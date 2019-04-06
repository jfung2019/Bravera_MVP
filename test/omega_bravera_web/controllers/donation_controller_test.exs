defmodule OmegaBraveraWeb.DonationControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  describe "show donations" do
    test "invalid challenge will show 404 instead of 500 error", %{conn: conn} do
      conn = get(conn, "/invalid-ngo/invalid-challenge/donors")

      assert html_response(conn, 404) =~ "You look lost, Mate."
    end
  end
end
