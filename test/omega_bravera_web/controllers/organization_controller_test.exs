defmodule OmegaBraveraWeb.OrganizationControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Accounts

  @create_attrs %{name: "some name", business_type: "type"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:organization) do
    {:ok, organization} = Accounts.create_organization(@create_attrs)
    organization
  end

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "index" do
    test "lists all organization", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_organization_path(conn, :index))
      assert html_response(conn, 200) =~ "Organizations"
    end
  end

  describe "new organization" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_organization_path(conn, :new)) |> IO.inspect()
      assert html_response(conn, 200) =~ "New Organization"
    end
  end

  describe "create organization" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.admin_panel_organization_path(conn, :create),
          organization: @create_attrs
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_panel_organization_path(conn, :show, id)

      conn = get(conn, Routes.admin_panel_organization_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Organization Details"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.admin_panel_organization_path(conn, :create),
          organization: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Organization"
    end
  end

  describe "edit organization" do
    setup [:create_organization]

    test "renders form for editing chosen organization", %{conn: conn, organization: organization} do
      conn = get(conn, Routes.admin_panel_organization_path(conn, :edit, organization))
      assert html_response(conn, 200) =~ "Edit Organization"
    end
  end

  describe "update organization" do
    setup [:create_organization]

    test "redirects when data is valid", %{conn: conn, organization: organization} do
      conn =
        put(conn, Routes.admin_panel_organization_path(conn, :update, organization),
          organization: @update_attrs
        )

      assert redirected_to(conn) ==
               Routes.admin_panel_organization_path(conn, :show, organization)

      conn = get(conn, Routes.admin_panel_organization_path(conn, :show, organization))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, organization: organization} do
      conn =
        put(conn, Routes.admin_panel_organization_path(conn, :update, organization),
          organization: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Organization"
    end
  end

  describe "delete organization" do
    setup [:create_organization]

    test "deletes chosen organization", %{conn: conn, organization: organization} do
      conn = delete(conn, Routes.admin_panel_organization_path(conn, :delete, organization))
      assert redirected_to(conn) == Routes.admin_panel_organization_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.admin_panel_organization_path(conn, :show, organization))
      end
    end
  end

  defp create_organization(_) do
    organization = fixture(:organization)
    %{organization: organization}
  end
end
