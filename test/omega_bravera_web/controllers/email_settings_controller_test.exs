defmodule OmegaBraveraWeb.EmailSettingsControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Repo, Challenges.Notifier}

  setup %{conn: conn} do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: "sheriefalaa.w@gmail.com",
      password: "test1234"
    }

    with {:ok, user} <- Accounts.create_user(attrs),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token), user: user}
  end

  describe "edit email settings" do
    test "edit/2 shows edit user email settings", %{conn: conn} do
      conn = get(conn, email_settings_path(conn, :edit))
      assert html_response(conn, 200) =~ "Email Settings"
    end

    test "update/2 saves email user settings when given correct params", %{conn: conn, user: user} do
      user =
        user
        |> Repo.preload(:subscribed_email_categories)

      update_params = %{"subscribed_categories" => ["1", "4"]}
      conn = post(conn, email_settings_path(conn, :update), update_params)

      updated_user =
        Accounts.get_user!(user.id)
        |> Repo.preload(:subscribed_email_categories)

      assert get_flash(conn, :info) =~ "Updated email settings sucessfully."
      assert hd(updated_user.subscribed_email_categories).category_id == 1
      assert hd(Enum.reverse(updated_user.subscribed_email_categories)).category_id == 4

      # Ensure an email from unsubscribed category will not be sent to sendgrid.
      challenge = insert(:ngo_challenge, %{user: updated_user})
      refute Notifier.send_participant_inactivity_email(challenge) == :ok
    end

    test "update/2 refuses to unsubscribe user from main emails category", %{conn: conn, user: user} do
      user =
        user
        |> Repo.preload(:subscribed_email_categories)

      update_params = %{"subscribed_categories" => ["1", "2"]}
      conn = post(conn, email_settings_path(conn, :update), update_params)

      updated_user =
        Accounts.get_user!(user.id)
        |> Repo.preload(:subscribed_email_categories)

      assert get_flash(conn, :error) =~ "Cannot unsubscribe from platform notification. Please request account termination from admin@bravera.co"
      assert Enum.empty?(updated_user.subscribed_email_categories)
    end
  end
end
