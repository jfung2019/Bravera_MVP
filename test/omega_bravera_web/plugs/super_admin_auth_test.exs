defmodule OmegaBraveraWeb.SuperAdminAuthTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  alias OmegaBraveraWeb.SuperAdminAuth
  alias OmegaBravera.Guardian.MaybeAuthPipeline

  test "can continue if they are a super admin", %{conn: conn} do
    {:ok, token, _} =
      Fixtures.admin_user_fixture(%{role: "super"})
      |> OmegaBravera.Guardian.encode_and_sign(%{})

    conn =
      conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> MaybeAuthPipeline.call(nil)
      |> SuperAdminAuth.call(nil)

    assert %{halted: false} = conn
  end

  test "will redirect non super admin user to partner section", %{conn: conn} do
    {:ok, token, _} =
      Fixtures.admin_user_fixture(%{role: "partner"})
      |> OmegaBravera.Guardian.encode_and_sign(%{})

    conn =
      conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> MaybeAuthPipeline.call(nil)
      |> SuperAdminAuth.call(nil)

    assert %{halted: true} = conn
    assert redirected_to(conn) =~ Routes.admin_panel_partner_path(conn, :index)
  end
end
