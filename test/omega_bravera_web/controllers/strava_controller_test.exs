defmodule OmegaBraveraWeb.StravaControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Trackers

  @create_attrs %{athlete_id: 42, email: "some email", firstname: "some firstname", lastname: "some lastname", token: "some token"}
  @update_attrs %{athlete_id: 43, email: "some updated email", firstname: "some updated firstname", lastname: "some updated lastname", token: "some updated token"}
  @invalid_attrs %{athlete_id: nil, email: nil, firstname: nil, lastname: nil, token: nil}

  def fixture(:strava) do
    {:ok, strava} = Trackers.create_strava(@create_attrs)
    strava
  end

  describe "index" do

    @tag :skip
    test "lists all stravas", %{conn: conn} do
      conn = get conn, strava_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Stravas"
    end
  end

  describe "new strava" do

    @tag :skip
    test "renders form", %{conn: conn} do
      conn = get conn, strava_path(conn, :new)
      assert html_response(conn, 200) =~ "New Strava"
    end
  end

  describe "create strava" do

    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, strava_path(conn, :create), strava: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == strava_path(conn, :show, id)

      conn = get conn, strava_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Strava"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, strava_path(conn, :create), strava: @invalid_attrs
      assert html_response(conn, 200) =~ "New Strava"
    end
  end

  describe "edit strava" do
    setup [:create_strava]

    @tag :skip
    test "renders form for editing chosen strava", %{conn: conn, strava: strava} do
      conn = get conn, strava_path(conn, :edit, strava)
      assert html_response(conn, 200) =~ "Edit Strava"
    end
  end

  describe "update strava" do
    setup [:create_strava]

    @tag :skip
    test "redirects when data is valid", %{conn: conn, strava: strava} do
      conn = put conn, strava_path(conn, :update, strava), strava: @update_attrs
      assert redirected_to(conn) == strava_path(conn, :show, strava)

      conn = get conn, strava_path(conn, :show, strava)
      assert html_response(conn, 200) =~ "some updated email"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, strava: strava} do
      conn = put conn, strava_path(conn, :update, strava), strava: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Strava"
    end
  end

  describe "delete strava" do
    setup [:create_strava]

    @tag :skip
    test "deletes chosen strava", %{conn: conn, strava: strava} do
      conn = delete conn, strava_path(conn, :delete, strava)
      assert redirected_to(conn) == strava_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, strava_path(conn, :show, strava)
      end
    end
  end

  defp create_strava(_) do
    strava = fixture(:strava)
    {:ok, strava: strava}
  end
end
