defmodule OmegaBraveraWeb.AdminUserPasswordControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}

  setup %{conn: conn} do
    location = Fixtures.location_fixture()
    {:ok, conn: conn, admin_user: Fixtures.admin_user_fixture()}
  end

  describe "new/2" do
    test "new/2 shows password reset form", %{conn: conn} do
      conn = get(conn, Routes.admin_user_password_path(conn, :new))
      assert html_response(conn, 200) =~ "Forgot Password"
    end
  end

  describe "create/2" do
    test "will setup a forgot password token for admin user", %{
      conn: conn,
      admin_user: %{id: user_id} = admin_user
    } do
      conn =
        post(conn, Routes.admin_user_password_path(conn, :create), %{
          reset_token: %{email: admin_user.email}
        })

      assert html_response(conn, 200) =~
               "Password reset link sent. Please check your inbox."

      %{reset_token: reset_token, reset_token_created: reset_token_created} =
        Accounts.get_admin_user!(user_id)

      assert reset_token != nil
      assert reset_token_created != nil
    end

    test "will tell user if they have no account", %{conn: conn} do
      conn =
        post(conn, Routes.admin_user_password_path(conn, :create), %{
          reset_token: %{email: "noexist@test.com"}
        })

      assert html_response(conn, 200) =~
               "There&#39;s no account associated with that email"
    end
  end

  describe "edit/2" do
    test "renders form for editing password", %{conn: conn, admin_user: admin_user} do
      {:ok, admin_user} = Accounts.send_reset_password_token(admin_user)
      conn = get(conn, Routes.admin_user_password_path(conn, :edit, admin_user.reset_token))
      assert html_response(conn, 200) =~ "Password reset"
    end

    test "redirects and shows error if token is bad", %{conn: conn} do
      conn = get(conn, Routes.admin_user_password_path(conn, :edit, "bad_token"))
      assert get_flash(conn, :error) =~ "Invalid reset token"
    end

    test "redirects and shows error if token expired", %{conn: conn, admin_user: admin_user} do
      token = "token"

      admin_user
      |> OmegaBravera.Accounts.AdminUser.reset_token_changeset()
      |> Ecto.Changeset.change(%{
        reset_token: token,
        reset_token_created: DateTime.truncate(Timex.shift(Timex.now(), hours: -3), :second)
      })
      |> OmegaBravera.Repo.update()

      conn = get(conn, Routes.admin_user_password_path(conn, :edit, token))
      assert get_flash(conn, :error) =~ "Password reset token expired"
    end
  end

  describe "update" do
    test "redirects and shows error if token expired", %{conn: conn, admin_user: admin_user} do
      token = "token"

      admin_user
      |> OmegaBravera.Accounts.AdminUser.reset_token_changeset()
      |> Ecto.Changeset.change(%{
        reset_token: token,
        reset_token_created: DateTime.truncate(Timex.shift(Timex.now(), hours: -3), :second)
      })
      |> OmegaBravera.Repo.update()

      attrs = %{
        "password" => "testing"
      }

      conn =
        put(
          conn,
          Routes.admin_user_password_path(conn, :update, token, admin_user: attrs)
        )

      assert get_flash(conn, :error) =~ "Password reset token expired"
    end

    test "saves new password", %{conn: conn, admin_user: admin_user} do
      {:ok, admin_user} = Accounts.send_reset_password_token(admin_user)

      attrs = %{
        "password" => "Test@ing1",
        "password_confirmation" => "Test@ing1"
      }

      conn =
        put(
          conn,
          Routes.admin_user_password_path(conn, :update, admin_user.reset_token, admin_user: attrs)
        )

      assert get_flash(conn, :info) =~ "Password reset successfully!"
    end
  end
end
