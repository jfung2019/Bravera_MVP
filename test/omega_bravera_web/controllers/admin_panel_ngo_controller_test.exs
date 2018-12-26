defmodule OmegaBraveraWeb.Admin.NGOControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Fundraisers, Challenges, Challenges.NGOChal}

  @ngo_create_attrs %{
    desc: "some desc",
    logo: "some logo",
    image: "/test.png",
    url: "http://test.com",
    name: "some name",
    slug: "some-slug",
    open_registration: false,
    pre_registration_start_date: Timex.shift(Timex.now(), days: 1),
    launch_date: Timex.shift(Timex.now(), days: 10)
  }

  @update_attrs %{
    desc: "some updated desc",
    logo: "some updated logo",
    name: "some updated name",
    slug: "some-updated-slug",
    open_registration: false,
    launch_date: Timex.shift(Timex.now(), days: 10)
  }

  @invalid_attrs %{
    desc: nil,
    logo: nil,
    name: nil,
    slug: nil,
    open_registration: nil,
    pre_registration_start_date: Timex.now(),
    launch_date: Timex.shift(Timex.now(), days: 10)
  }

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:ngo) do
    {:ok, ngo} = Fundraisers.create_ngo(@ngo_create_attrs)
    ngo = %{ngo | utc_launch_date: ngo.launch_date}

    {:ok, user} = Accounts.create_user(%{email: "sheriefalaa.w@gmail.com"})

    ngo_chal_attrs = %{
      "activity_type" => "Walk",
      "money_target" => 500,
      "distance_target" => 50,
      "status" => "pre_registration",
      "duration" => 30,
      "user_id" => user.id,
      "ngo_id" => ngo.id,
      "slug" => "some-closed-registration-challenge",
      "type" => "PER_KM"
    }

    {:ok, _ngo_chal} = Challenges.create_ngo_chal(%NGOChal{}, ngo, ngo_chal_attrs)
    ngo
  end

  describe "index" do
    setup [:create_ngo]

    test "lists all ngos in admin panel", %{conn: conn} do
      conn = get(conn, admin_panel_ngo_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing NGOs"
    end
  end

  describe "show" do
    setup [:create_ngo]

    test "shows a specific ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, admin_panel_ngo_path(conn, :show, ngo))
      assert html_response(conn, 200) =~ "Challenges:"
    end
  end

  describe "new ngo" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_panel_ngo_path(conn, :new))
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "create ngo" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, admin_panel_ngo_path(conn, :create), ngo: @ngo_create_attrs)
      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == admin_panel_ngo_path(conn, :show, slug)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_panel_ngo_path(conn, :create), ngo: %{name: ""})
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "edit ngo" do
    setup [:create_ngo]

    test "renders form for editing chosen ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, admin_panel_ngo_path(conn, :edit, ngo))
      assert html_response(conn, 200)
    end
  end

  describe "update ngo" do
    setup [:create_ngo]

    test "redirects when data is valid after updating", %{conn: conn, ngo: ngo} do
      conn = put(conn, admin_panel_ngo_path(conn, :update, ngo), ngo: @update_attrs)
      assert redirected_to(conn) == admin_panel_ngo_path(conn, :index)
    end

    test "renders errors in update when data is invalid", %{conn: conn, ngo: ngo} do
      conn = put(conn, admin_panel_ngo_path(conn, :update, ngo), ngo: @invalid_attrs)
      assert html_response(conn, 200)
    end

    test "when updating closed registration launch date, all its pre_registration challenges' start_date is also updated",
         %{conn: conn, ngo: ngo} do
      conn =
        put(conn, admin_panel_ngo_path(conn, :update, ngo),
          ngo: %{launch_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 20)}
        )

      assert html_response(conn, 302)

      updated_ngo = Fundraisers.get_ngo_by_slug(ngo.slug)
      ngo_chal = updated_ngo.ngo_chals |> List.first()

      assert Timex.equal?(updated_ngo.launch_date, ngo_chal.start_date)
    end
  end

  defp create_ngo(_) do
    ngo = fixture(:ngo)
    {:ok, ngo: ngo}
  end
end
