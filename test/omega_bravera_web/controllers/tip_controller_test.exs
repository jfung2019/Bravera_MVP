defmodule OmegaBraveraWeb.TipControllerTest do
  use OmegaBraveraWeb.ConnCase

  alias OmegaBravera.Money

  @create_attrs %{amount: 42, currency: "some currency"}
  @update_attrs %{amount: 43, currency: "some updated currency"}
  @invalid_attrs %{amount: nil, currency: nil}

  def fixture(:tip) do
    {:ok, tip} = Money.create_tip(@create_attrs)
    tip
  end

  describe "new tip" do
    test "renders form", %{conn: conn} do
      conn = get conn, tip_path(conn, :new)
      assert html_response(conn, 200) =~ "New Tip"
    end
  end

  describe "create tip" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, tip_path(conn, :create), tip: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == tip_path(conn, :show, id)

      conn = get conn, tip_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Tip"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, tip_path(conn, :create), tip: @invalid_attrs
      assert html_response(conn, 200) =~ "New Tip"
    end
  end

  defp create_tip(_) do
    tip = fixture(:tip)
    {:ok, tip: tip}
  end
end
