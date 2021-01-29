defmodule OmegaBraveraWeb.MaybeAuthPipelineTest do
  use OmegaBraveraWeb.ConnCase, async: true
  import OmegaBravera.Factory

  test "expired token should redirect to login and give cookie to redirect to previous path after login",
       %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{exp: 1})

    conn =
      conn
      |> Plug.Conn.put_req_header("authorization", "bearer: " <> token)
      |> bypass_through(OmegaBravera.Router, :browser)
      |> get("/offers")

    assert redirected_to(conn) =~ "/"
    assert get_session(conn, "after_login_redirect") =~ "/offers"
  end
end
