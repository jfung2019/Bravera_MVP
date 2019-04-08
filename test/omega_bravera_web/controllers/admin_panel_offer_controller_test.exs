defmodule OmegaBraveraWeb.Admin.OfferControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Offers}

  @offer_create_attrs %{
    name: "test offer",
    slug: nil,
    url: "https://example.com",
    logo: "some logo",
    offer_challenge_types: ["PER_KM"],
    distances: ["50"],
    activities: ["Walk"],
    start_date: Timex.now(),
    end_date: Timex.shift(Timex.now(), days: 30),
    toc: "some toc",
    vendor_id: nil
  }

  @update_attrs %{
    name: "test offer",
    slug: "updated-slug",
    url: "https://example2.com",
    logo: "some logo2",
    offer_challenge_types: ["PER_KM"],
    distances: ["25"],
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
    logo: nil,
    offer_challenge_types: nil,
    distances: nil,
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
      conn = get(conn, admin_panel_offer_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Offers"
    end
  end

  describe "new offer" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_panel_offer_path(conn, :new))
      assert html_response(conn, 200) =~ "New Offer"
    end
  end

  describe "create offer" do
    test "redirects to show when data is valid", %{conn: conn} do
      {:ok, vendor} = Offers.create_offer_vendor(%{vendor_id: "331678", email: "foo@bar.com"})

      conn =
        post(conn, admin_panel_offer_path(conn, :create),
          offer: Map.put(@offer_create_attrs, :vendor_id, vendor.id)
        )

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == admin_panel_offer_path(conn, :show, slug)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_panel_offer_path(conn, :create), offer: %{name: ""})
      assert html_response(conn, 200) =~ "New Offer"
    end
  end

  describe "edit offer" do
    setup [:create_offer]

    test "renders form for editing chosen offer", %{conn: conn, offer: offer} do
      conn = get(conn, admin_panel_offer_path(conn, :edit, offer))
      assert html_response(conn, 200)
    end
  end

  describe "update offer" do
    setup [:create_offer]

    test "update when data is valid", %{conn: conn, offer: offer} do
      {:ok, vendor} = Offers.create_offer_vendor(%{vendor_id: "312322", email: "foo@bar.com"})

      put(conn, admin_panel_offer_path(conn, :update, offer.slug),
        offer: Map.put(@update_attrs, :vendor_id, vendor.id)
      )

      updated_offer = Offers.get_offer!(offer.id)
      assert updated_offer.slug == @update_attrs.slug
      assert updated_offer.vendor_id == vendor.id
    end

    test "renders errors in update when data is invalid", %{conn: conn, offer: offer} do
      conn = put(conn, admin_panel_offer_path(conn, :update, offer.slug), offer: @invalid_attrs)
      assert html_response(conn, 200)
    end
  end

  defp create_offer(_) do
    offer = fixture(:offer)
    {:ok, offer: offer}
  end
end
