defmodule OmegaBraveraWeb.MerchantConstraintTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    location = Fixtures.location_fixture()

    {:ok, %{partner_user: partner_user}} =
      Accounts.create_partner_user_and_organization(%{
        "partner_user" => %{
          "username" => "test",
          "email" => "test@email.com",
          "password" => "Test@123456",
          "password_confirmation" => "Test@123456",
          "email_verified" => true,
          "location_id" => location.id,
          "first_name" => "first",
          "last_name" => "last",
          "contact_number" => "12345678",
          "accept_terms" => true
        },
        "organization" => %{
          "name" => "test",
          "business_type" => "test",
          "business_website" => "test.com",
          "account_type" => :merchant
        }
      })

    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(partner_user, %{})

    {:ok, conn: put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  test "can only access allowed paths", %{conn: conn} do
    conn = get(conn, Routes.org_panel_partner_path(conn, :index))

    assert redirected_to(conn) =~ Routes.org_panel_online_offers_path(conn, :index)
  end
end
