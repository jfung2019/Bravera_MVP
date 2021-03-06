defmodule OmegaBraveraWeb.PartnerUserPasswordControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    location = Fixtures.location_fixture()
    {:ok, conn: conn, partner_user: Fixtures.partner_user_fixture(%{location_id: location.id})}
  end

  describe "new/2" do
    test "new/2 shows password reset form", %{conn: conn} do
      conn = get(conn, Routes.partner_user_password_path(conn, :new))
      assert html_response(conn, 200) =~ "Forgot Password"
    end
  end

  describe "create/2" do
    test "will setup a forgot password token for partner user", %{
      conn: conn,
      partner_user: %{id: user_id} = partner_user
    } do
      conn =
        post(conn, Routes.partner_user_password_path(conn, :create), %{
          partner_user: %{email: partner_user.email}
        })

      assert html_response(conn, 200) =~
               "Password reset link sent. Please check your inbox."

      %{reset_token: reset_token, reset_token_created: reset_token_created} =
        Accounts.get_partner_user!(user_id)

      assert reset_token != nil
      assert reset_token_created != nil
    end

    test "will tell user if they have no account", %{conn: conn} do
      conn =
        post(conn, Routes.partner_user_password_path(conn, :create), %{
          partner_user: %{email: "noexist@test.com"}
        })

      assert html_response(conn, 200) =~
               "There&#39;s no account associated with that username or email"
    end
  end

  describe "edit/2" do
    test "renders form for editing password", %{conn: conn, partner_user: partner_user} do
      partner_user = Accounts.reset_partner_user_password(partner_user)
      conn = get(conn, Routes.partner_user_password_path(conn, :edit, partner_user.reset_token))
      assert html_response(conn, 200) =~ "Password reset"
    end

    test "redirects and shows error if token is bad", %{conn: conn} do
      conn = get(conn, Routes.partner_user_password_path(conn, :edit, "bad_token"))
      assert get_flash(conn, :error) =~ "Invalid reset token"
    end

    test "redirects and shows error if token expired", %{conn: conn, partner_user: partner_user} do
      token = "token"

      partner_user
      |> OmegaBravera.Accounts.PartnerUser.reset_password_changeset(%{
        reset_token: token,
        reset_token_created: Timex.shift(Timex.now(), days: -1)
      })
      |> OmegaBravera.Repo.update()

      conn = get(conn, Routes.partner_user_password_path(conn, :edit, token))
      assert get_flash(conn, :error) =~ "Password reset token expired"
    end
  end

  describe "update" do
    test "redirects and shows error if token expired", %{conn: conn, partner_user: partner_user} do
      token = "token"

      partner_user
      |> OmegaBravera.Accounts.PartnerUser.reset_password_changeset(%{
        reset_token: token,
        reset_token_created: Timex.shift(Timex.now(), days: -1)
      })
      |> OmegaBravera.Repo.update()

      attrs = %{
        "password" => "testing"
      }

      conn =
        put(
          conn,
          Routes.partner_user_password_path(conn, :update, token, partner_user: attrs)
        )

      assert get_flash(conn, :error) =~ "Password reset token expired"
    end

    test "saves new password", %{conn: conn, partner_user: partner_user} do
      partner_user = Accounts.reset_partner_user_password(partner_user)

      attrs = %{
        "password" => "Test@ing1",
        "password_confirmation" => "Test@ing1"
      }

      conn =
        put(
          conn,
          Routes.partner_user_password_path(conn, :update, partner_user.reset_token,
            partner_user: attrs
          )
        )

      assert get_flash(conn, :info) =~ "Password reset successfully!"
    end
  end
end
