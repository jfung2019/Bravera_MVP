defmodule OmegaBraveraWeb.PasswordControllerTest do
  use OmegaBraveraWeb.ConnCase

  import OmegaBravera.Factory

  alias OmegaBravera.Accounts

  setup %{conn: conn} do
    {:ok, conn: conn, credential: insert(:credential)}
  end

  describe "new/2" do
    test "new/2 shows password reset form", %{conn: conn} do
      conn = get(conn, password_path(conn, :new))
      assert html_response(conn, 200) =~ "Password reset"
    end
  end

  describe "edit/2" do
    test "renders form for editing password", %{conn: conn, credential: credential} do
      {:ok, updated_credential} =
        Accounts.update_credential_token(credential, %{
          reset_token: "foo_token",
          reset_token_created: Timex.now()
        })

      conn = get(conn, password_path(conn, :edit, updated_credential))
      assert html_response(conn, 200) =~ "Password reset"
    end

    test "redirects and shows error if token is bad", %{conn: conn, credential: credential} do
      conn = get(conn, password_path(conn, :edit, %{credential | reset_token: "bad_token"}))
      assert get_flash(conn, :error) =~ "Invalid reset token"
    end

    test "redirects and shows error if token expired", %{conn: conn, credential: credential} do
      {:ok, updated_credential} =
        Accounts.update_credential_token(credential, %{
          reset_token: "foo_token",
          reset_token_created: Timex.shift(Timex.now(), days: -3)
        })

      conn = get(conn, password_path(conn, :edit, updated_credential))
      assert get_flash(conn, :error) =~ "Password reset token expired"
    end
  end

  describe "update" do
    test "redirects and shows error if token expired", %{conn: conn, credential: credential} do
      {:ok, updated_credential} =
        Accounts.update_credential_token(credential, %{
          reset_token: "foo_token",
          reset_token_created: Timex.shift(Timex.now(), days: -3)
        })

      attrs = %{
        "password" => "testing",
        "password_confirmation" => "testing"
      }

      conn = put(conn, password_path(conn, :update, updated_credential, credential: attrs))
      assert get_flash(conn, :error) =~ "Password reset token expired"
    end

    test "saves new password", %{conn: conn, credential: credential} do
      {:ok, updated_credential} =
        Accounts.update_credential_token(credential, %{
          reset_token: "foo_token",
          reset_token_created: Timex.now()
        })

      attrs = %{
        "password" => "testing",
        "password_confirmation" => "testing"
      }

      conn = put(conn, password_path(conn, :update, updated_credential, credential: attrs))
      assert get_flash(conn, :info) =~ "Password reset successfully!"
    end
  end
end
