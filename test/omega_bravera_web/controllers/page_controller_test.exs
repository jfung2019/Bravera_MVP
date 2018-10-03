defmodule OmegaBraveraWeb.PageControllerTest do
  use OmegaBraveraWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Bravera"
  end
end
