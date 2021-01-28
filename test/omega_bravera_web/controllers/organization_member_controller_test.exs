defmodule OmegaBraveraWeb.OrganizationMemberControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "index" do
    test "lists all organization_members", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_organization_member_path(conn, :index))
      assert html_response(conn, 200) =~ "Organization members"
    end
  end

  describe "new organization_member" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_organization_member_path(conn, :new))
      assert html_response(conn, 200) =~ "New Organization member"
    end
  end

  describe "create organization_member" do
    test "redirects to show when data is valid", %{conn: conn} do
      {:ok, organization} = Accounts.create_organization(%{name: "test2", business_type: "test2"})
      location = Fixtures.location_fixture()

      conn =
        post(conn, Routes.admin_panel_organization_member_path(conn, :create),
          organization_member: %{
            username: "name",
            email: "iu@email.com",
            password_confirmation: "123456",
            password: "123456",
            business_type: "type",
            first_name: "First Name",
            last_name: "Last Name",
            location_id: location.id,
            contact_number: "00000000",
            accept_terms: true,
            organization_id: organization.id
          }
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_panel_organization_member_path(conn, :show, id)

      conn = get(conn, Routes.admin_panel_organization_member_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Organization member"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      {:ok, organization} = Accounts.create_organization(%{name: "test2", business_type: "test2"})

      conn =
        post(conn, Routes.admin_panel_organization_member_path(conn, :create),
          organization_member: %{organization_id: organization.id}
        )

      assert html_response(conn, 200) =~ "New Organization member"
    end
  end

  describe "edit organization_member" do
    setup [:create_organization_member]

    test "renders form for editing chosen organization_member", %{
      conn: conn,
      organization_member: organization_member
    } do
      conn =
        get(conn, Routes.admin_panel_organization_member_path(conn, :edit, organization_member))

      assert html_response(conn, 200) =~ "Edit Organization member"
    end
  end

  describe "update organization_member" do
    setup [:create_organization_member]

    test "redirects when data is valid", %{
      conn: conn,
      organization_member: organization_member
    } do
      conn =
        put(conn, Routes.admin_panel_organization_member_path(conn, :update, organization_member),
          partner_user: %{
            username: "name2",
            email: "iu@email.com",
            password: "123456",
            password_confirmation: "123456"
          }
        )

      assert redirected_to(conn) ==
               Routes.admin_panel_organization_member_path(conn, :show, organization_member)

      conn =
        get(conn, Routes.admin_panel_organization_member_path(conn, :show, organization_member))

      assert html_response(conn, 200)
    end

    #    test "renders errors when data is invalid", %{
    #      conn: conn,
    #      organization_member: organization_member
    #    } do
    #      conn =
    #        put(conn, Routes.admin_panel_organization_member_path(conn, :update, organization_member),
    #          partner_user: %{
    #            "username": "name2",
    #            "email": "iu@em",
    #            "password": "123456",
    #            "business_type": "type",
    #            "accept_terms": true
    #          }
    #        )
    #
    #      assert html_response(conn, 200) =~ "Edit Organization member"
    #    end
  end

  describe "delete organization_member" do
    setup [:create_organization_member]

    test "deletes chosen organization_member", %{
      conn: conn,
      organization_member: organization_member
    } do
      conn =
        delete(
          conn,
          Routes.admin_panel_organization_member_path(conn, :delete, organization_member)
        )

      assert redirected_to(conn) == Routes.admin_panel_organization_member_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.admin_panel_organization_member_path(conn, :show, organization_member))
      end
    end
  end

  defp create_organization_member(_) do
    {:ok, organization} = Accounts.create_organization(%{name: "test", business_type: "test"})
    location = Fixtures.location_fixture()

    organization_member_params = %{
      username: "name",
      email: "iu@email.com",
      password: "123456",
      password_confirmation: "123456",
      first_name: "First Name",
      last_name: "Last Name",
      location_id: location.id,
      contact_number: "00000000",
      business_type: "type",
      accept_terms: true
    }

    {:ok, %{create_organization_member: organization_member}} =
      Accounts.create_organization_partner_user(organization.id, organization_member_params)

    %{organization_member: organization_member, organization: organization}
  end
end
