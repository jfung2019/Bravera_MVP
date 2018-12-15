defmodule OmegaBraveraWeb.SettingControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts

  @create_attrs %{
    location: "UK",
    weight: 31.4,
    date_of_birth: "1940-07-14",
    gender: "Female"
  }
  @update_attrs %{
    location: "US",
    weight: "30",
    date_of_birth: "1980-07-14",
    gender: "Male",
    weight_fraction: "0.5"
  }
  @invalid_attrs %{
    location: nil,
    weight: "30",
    weight_fraction: "0.4",
    date_of_birth: nil,
    gender: nil,
    user_id: nil
  }

  def setting_fixture(user_id) do
    {:ok, _setting} =
      @create_attrs
      |> Map.put(:user_id, user_id)
      |> Accounts.create_setting()
  end

  setup %{conn: conn} do
    with {:ok, user} <- Accounts.create_user(%{email: "user@example.com"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         {:ok, _setting} <- setting_fixture(user.id),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  describe "edit setting" do
    test "renders form for editing chosen setting", %{conn: conn} do
      conn = get(conn, setting_path(conn, :edit))
      assert html_response(conn, 200) =~ "Edit Settings"
    end
  end

  describe "update setting" do
    test "redirects when data is valid", %{conn: conn} do
      conn = put(conn, setting_path(conn, :update), setting: @update_attrs)
      assert redirected_to(conn) == setting_path(conn, :show)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, setting_path(conn, :update, %{"setting" => @invalid_attrs}))

      assert html_response(conn, 200) =~
               "Oops, something went wrong! Please check the errors below."
    end
  end
end
