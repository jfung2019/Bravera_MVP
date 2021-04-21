defmodule OmegaBraveraWeb.NGOControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  describe "show ngo" do
    test "invalid NGO slug will result in 404 reply", %{conn: conn} do
      conn = get(conn, "/invalid-ngo")
      assert html_response(conn, 404) =~ "You look lost, Mate."
    end

    @tag :skip
    test "valid NGO slug will result in 200", %{conn: conn} do
      ngo = insert(:ngo)
      conn = get(conn, "/#{ngo.slug}")
      assert response = html_response(conn, 200)
      refute response =~ "You look lost, Mate."
    end
  end
end
