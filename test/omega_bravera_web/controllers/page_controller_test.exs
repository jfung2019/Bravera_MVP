defmodule OmegaBraveraWeb.PageControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) =~ "https://www.bravera.fit"
  end

  test "GET really long URL returns 404", %{conn: conn} do
    conn = get(conn, "/really/long/url")
    assert html_response(conn, 404) =~ "You look lost, Mate."
  end

  test "healthcheck returns 200 response", %{conn: conn} do
    conn = get(conn, "/health-check")
    assert html_response(conn, 200) == ""
  end
end
