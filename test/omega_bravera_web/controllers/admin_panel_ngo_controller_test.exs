defmodule OmegaBraveraWeb.Admin.NGOControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Fundraisers, Challenges, Challenges.NGOChal}

  @ngo_create_attrs %{
    desc: "some desc",
    url: "http://test.com",
    name: "some name",
    slug: nil,
    open_registration: false,
    pre_registration_start_date: Timex.shift(Timex.now(), days: 1),
    launch_date: Timex.shift(Timex.now(), days: 10),
    additional_members: 0,
    user_id: nil
  }

  @update_attrs %{
    desc: "some updated desc",
    name: "some updated name",
    slug: "some-updated-slug",
    open_registration: false,
    launch_date: Timex.shift(Timex.now(), days: 10)
  }

  @invalid_attrs %{
    desc: nil,
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
    user_attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: "user@example.com",
      password: "test1234",
      location_id: 1
    }

    {:ok, user} = Accounts.create_user(user_attrs)

    {:ok, ngo} = Fundraisers.create_ngo(%{@ngo_create_attrs | user_id: user.id})
    ngo = %{ngo | utc_launch_date: ngo.launch_date}

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

    {:ok, _ngo_chal} = Challenges.create_ngo_chal(%NGOChal{}, ngo, user, ngo_chal_attrs)
    ngo
  end

  describe "index" do
    setup [:create_ngo]

    test "lists all ngos in admin panel", %{conn: conn} do
      conn = get(conn, admin_panel_ngo_path(conn, :index))
      assert html_response(conn, 200) =~ "NGOs"
    end
  end

  describe "show" do
    setup [:create_ngo]

    test "shows a specific ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, Routes.admin_panel_ngo_path(conn, :show, ngo))
      assert html_response(conn, 200) =~ "Challenges:"
    end
  end

  describe "new ngo" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_ngo_path(conn, :new))
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "create ngo" do
    test "redirects to show when data is valid", %{conn: conn} do
      attrs = %{
        firstname: "sherief",
        lastname: "alaa ",
        email: "user@example.com",
        password: "test1234",
        location_id: 1
      }

      {:ok, user} = Accounts.create_user(attrs)

      conn =
        post(conn, Routes.admin_panel_ngo_path(conn, :create),
          ngo: %{@ngo_create_attrs | user_id: user.id}
        )

      assert %{slug: slug} = redirected_params(conn)

      ngo = Fundraisers.get_ngo_by_slug(slug)
      assert ngo.slug == "some-name"

      assert redirected_to(conn) == Routes.admin_panel_ngo_path(conn, :show, slug)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.admin_panel_ngo_path(conn, :create), ngo: %{name: ""})
      assert html_response(conn, 200) =~ "New NGO"
    end
  end

  describe "edit ngo" do
    setup [:create_ngo]

    test "renders form for editing chosen ngo", %{conn: conn, ngo: ngo} do
      conn = get(conn, Routes.admin_panel_ngo_path(conn, :edit, ngo))
      assert html_response(conn, 200)
    end
  end

  describe "update ngo" do
    setup [:create_ngo]

    test "redirects when data is valid after updating", %{conn: conn, ngo: ngo} do
      conn = put(conn, Routes.admin_panel_ngo_path(conn, :update, ngo), ngo: @update_attrs)

      updated_ngo = Fundraisers.get_ngo_by_slug(@update_attrs.slug)
      assert updated_ngo.slug == @update_attrs.slug

      assert redirected_to(conn) == Routes.admin_panel_ngo_path(conn, :index)
    end

    test "renders errors in update when data is invalid", %{conn: conn, ngo: ngo} do
      conn = put(conn, Routes.admin_panel_ngo_path(conn, :update, ngo), ngo: @invalid_attrs)
      assert html_response(conn, 200)
    end

    test "when updating closed registration launch date, all its pre_registration challenges' start_date is also updated",
         %{conn: conn, ngo: ngo} do
      conn =
        put(conn, Routes.admin_panel_ngo_path(conn, :update, ngo),
          ngo: %{launch_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 20)}
        )

      assert html_response(conn, 302)

      updated_ngo = Fundraisers.get_ngo_by_slug(ngo.slug)
      ngo_chal = updated_ngo.ngo_chals |> List.first()

      assert Timex.equal?(updated_ngo.launch_date, ngo_chal.start_date)
    end

    test "redirects and accepts additional_members (teams enabled ngo)", %{conn: conn, ngo: ngo} do
      conn =
        put(conn, admin_panel_ngo_path(conn, :update, ngo),
          ngo: Map.put(@update_attrs, :additional_members, 5)
        )

      updated_ngo = Fundraisers.get_ngo!(ngo.id)
      assert ngo.additional_members == 0
      assert updated_ngo.additional_members == 5
      assert redirected_to(conn) == Routes.admin_panel_ngo_path(conn, :index)
    end
  end

  defp create_ngo(_) do
    ngo = fixture(:ngo)
    {:ok, ngo: ngo}
  end
end
