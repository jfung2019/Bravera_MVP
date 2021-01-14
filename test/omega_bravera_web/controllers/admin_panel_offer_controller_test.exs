defmodule OmegaBraveraWeb.Admin.OfferControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Offers}

  @offer_create_attrs %{
    name: "test offer",
    slug: nil,
    url: "https://example.com",
    offer_challenge_types: ["PER_KM"],
    target: 50,
    activities: ["Walk"],
    start_date: Timex.now(),
    end_date: Timex.shift(Timex.now(), days: 30),
    toc: "some toc",
    vendor_id: nil,
    location_id: 1
  }

  @update_attrs %{
    name: "test offer",
    slug: "updated-slug",
    url: "https://example2.com",
    offer_challenge_types: ["PER_KM"],
    target: 25,
    activities: ["Run"],
    start_date: Timex.now(),
    end_date: Timex.shift(Timex.now(), days: 80),
    toc: "some toc2",
    vendor_id: nil
  }

  @invalid_attrs %{
    name: nil,
    slug: nil,
    url: nil,
    offer_challenge_types: nil,
    target: nil,
    activities: nil,
    start_date: nil,
    end_date: nil,
    toc: nil,
    vendor_id: nil
  }

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "test1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:offer) do
    {:ok, vendor} = Offers.create_offer_vendor(%{vendor_id: "123456", email: "foo@bar.com"})
    {:ok, offer} = Offers.create_offer(Map.put(@offer_create_attrs, :vendor_id, vendor.id))
    offer
  end

  describe "index" do
    setup [:create_offer]

    test "lists all offers in admin panel", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_offer_path(conn, :index))
      assert html_response(conn, 200) =~ "Offers"
    end
  end

  describe "new offer" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_panel_offer_path(conn, :new))
      assert html_response(conn, 200) =~ "New Offer"
    end
  end

  describe "create offer" do
    test "redirects to show when data is valid", %{conn: conn} do
      {:ok, vendor} = Offers.create_offer_vendor(%{vendor_id: "331678", email: "foo@bar.com"})

      conn =
        post(conn, Routes.admin_panel_offer_path(conn, :create),
          offer: Map.put(@offer_create_attrs, :vendor_id, vendor.id), offer_type: "in_store"
        )

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_panel_offer_path(conn, :show, slug)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.admin_panel_offer_path(conn, :create), offer: %{name: ""}, offer_type: "in_store")
      assert html_response(conn, 200) =~ "New Offer"
    end
  end

  describe "edit offer" do
    setup [:create_offer]

    test "renders form for editing chosen offer", %{conn: conn, offer: offer} do
      conn = get(conn, Routes.admin_panel_offer_path(conn, :edit, offer))
      assert html_response(conn, 200)
    end
  end

  describe "update offer" do
    setup [:create_offer]

    test "update when data is valid", %{conn: conn, offer: offer} do
      {:ok, vendor} = Offers.create_offer_vendor(%{vendor_id: "312322", email: "foo@bar.com"})

      put(conn, Routes.admin_panel_offer_path(conn, :update, offer.slug),
        offer: Map.put(@update_attrs, :vendor_id, vendor.id)
      )

      updated_offer = Offers.get_offer!(offer.id)
      assert updated_offer.slug == @update_attrs.slug
      assert updated_offer.vendor_id == vendor.id
    end

    test "renders errors in update when data is invalid", %{conn: conn, offer: offer} do
      conn = put(conn, Routes.admin_panel_offer_path(conn, :update, offer.slug), offer: @invalid_attrs)
      assert html_response(conn, 200)
    end

    test "when updating closed registration start date, all its pre_registration challenges' start_date is also updated",
         %{conn: conn} do
      offer =
        insert(:offer, %{
          open_registration: false,
          pre_registration_start_date: Timex.now(),
          start_date: Timex.shift(Timex.now(), days: 5),
          end_date: Timex.shift(Timex.now(), days: 10),
          time_limit: 0,
          location_id: 1
        })

      Offers.create_offer_challenge(offer, insert(:user))

      conn =
        put(conn, Routes.admin_panel_offer_path(conn, :update, offer),
          offer: %{start_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 15)}
        )

      assert html_response(conn, 302)

      updated_offer = Offers.get_offer_by_slug(offer.slug)
      offer_challenge = updated_offer.offer_challenges |> List.first()

      assert Timex.equal?(updated_offer.start_date, offer_challenge.start_date)
    end
  end

  defp create_offer(_) do
    offer = fixture(:offer)
    {:ok, offer: offer}
  end
end
