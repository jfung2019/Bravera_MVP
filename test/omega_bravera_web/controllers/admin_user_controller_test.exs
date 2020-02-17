defmodule OmegaBraveraWeb.AdminUserControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts

  @create_attrs %{email: "some@email.com", password: "pass1234"}
  @update_attrs %{email: "some.updated@email.com", password: "notpass1234"}
  @invalid_attrs %{email: nil, password: nil}

  def fixture(:admin_user) do
    {:ok, admin_user} = Accounts.create_admin_user(@create_attrs)
    admin_user
  end

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "index" do
    test "lists all admin_users", %{conn: conn} do
      conn = get(conn, admin_user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Admin Users"
    end
  end

  describe "new admin_user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_user_path(conn, :new))
      assert html_response(conn, 200) =~ "New Admin user"
    end
  end

  describe "create admin_user" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, admin_user_path(conn, :create), admin_user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == admin_user_path(conn, :show, id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_user_path(conn, :create), admin_user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Admin user"
    end
  end

  describe "edit admin_user" do
    setup [:create_admin_user]

    test "renders form for editing chosen admin_user", %{conn: conn, admin_user: admin_user} do
      conn = get(conn, admin_user_path(conn, :edit, admin_user))
      assert html_response(conn, 200) =~ "Edit Admin User"
    end
  end

  describe "update admin_user" do
    setup [:create_admin_user]

    test "redirects when data is valid", %{conn: conn, admin_user: admin_user} do
      conn = put(conn, admin_user_path(conn, :update, admin_user), admin_user: @update_attrs)
      assert redirected_to(conn) == admin_user_path(conn, :show, admin_user)

      admin_user = Accounts.get_admin_user!(admin_user.id)
      assert admin_user.email == "some.updated@email.com"
    end

    test "renders errors when data is invalid", %{conn: conn, admin_user: admin_user} do
      conn = put(conn, admin_user_path(conn, :update, admin_user), admin_user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Admin User"
    end
  end

  describe "delete admin_user" do
    setup [:create_admin_user]

    test "deletes chosen admin_user", %{conn: conn, admin_user: admin_user} do
      conn = delete(conn, admin_user_path(conn, :delete, admin_user))
      assert redirected_to(conn) == admin_user_path(conn, :index)
      refute admin_user in Accounts.list_admin_users()
    end
  end

  defp create_admin_user(_) do
    admin_user = fixture(:admin_user)
    {:ok, admin_user: admin_user}
  end
end
