defmodule OmegaBraveraWeb.SettingControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Accounts

  @create_attrs %{email_notifications: true, facebook: "some facebook", instagram: "some instagram", location: "some location", request_delete: true, show_lastname: true, twitter: "some twitter"}
  @update_attrs %{email_notifications: false, facebook: "some updated facebook", instagram: "some updated instagram", location: "some updated location", request_delete: false, show_lastname: false, twitter: "some updated twitter"}
  @invalid_attrs %{email_notifications: nil, facebook: nil, instagram: nil, location: nil, request_delete: nil, show_lastname: nil, twitter: nil}

  def fixture(:setting) do
    {:ok, setting} = Accounts.create_setting(@create_attrs)
    setting
  end

  describe "edit setting" do
    setup [:create_setting]

    @tag :skip
    test "renders form for editing chosen setting", %{conn: conn, setting: setting} do
      conn = get conn, setting_path(conn, :edit, setting)
      assert html_response(conn, 200) =~ "Edit Setting"
    end
  end

  describe "update setting" do
    setup [:create_setting]

    @tag :skip
    test "redirects when data is valid", %{conn: conn, setting: setting} do
      conn = put conn, setting_path(conn, :update, setting), setting: @update_attrs
      assert redirected_to(conn) == setting_path(conn, :show, setting)

      conn = get conn, setting_path(conn, :show, setting)
      assert html_response(conn, 200) =~ "some updated facebook"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, setting: setting} do
      conn = put conn, setting_path(conn, :update, setting), setting: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Setting"
    end
  end

  defp create_setting(_) do
    setting = fixture(:setting)
    {:ok, setting: setting}
  end
end
