defmodule OmegaBraveraWeb.ChangePasswordControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Accounts

  @credential_arrts %{
    password: "strong password",
    password_confirmation: "strong password"
  }

  @update_attrs %{
    "password" => "strong password 2",
    "password_confirmation" => "strong password 2"
  }

  @invalid_attrs %{
    "password" => "strong password 2",
    "password_confirmation" => nil
  }

  def credential_fixture(user_id) do
    {:ok, _credential} = Accounts.create_credential(user_id, @credential_arrts)
  end

  setup %{conn: conn} do
    attrs = %{firstname: "sherief", lastname: "alaa ", email: "user@example.com", password: "test1234"}

    with {:ok, user} <- Accounts.create_user(attrs),
         {:ok, _setting} <- credential_fixture(user.id),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "update change password" do
    test "redirects when data is valid", %{conn: conn} do
      conn = put(conn, change_password_path(conn, :update), %{"credential" => @update_attrs})
      assert redirected_to(conn) == user_profile_path(conn, :show)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, change_password_path(conn, :update, %{"credential" => @invalid_attrs}))

      assert html_response(conn, 200) =~
               "Oops, something went wrong! Please check the errors below."
    end
  end

  describe "edit change password" do
    test "renders form for editing password", %{conn: conn} do
      conn = get(conn, change_password_path(conn, :edit))
      assert html_response(conn, 200) =~ "Change Password"
    end
  end
end
