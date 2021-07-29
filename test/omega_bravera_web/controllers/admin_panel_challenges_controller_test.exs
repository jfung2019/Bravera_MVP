defmodule OmegaBraveraWeb.Admin.ChallengesControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts

  @user_create_attrs %{
    email: "test@test.com",
    firstname: "some firstname",
    lastname: "some lastname",
    location_id: 1
  }

  setup %{conn: conn} do
    with {:ok, admin_user} <-
           Accounts.create_admin_user(%{email: "god@god.com", password: "Test@1234"}),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(admin_user, %{}),
         do: {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)}
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@user_create_attrs)
    user
  end

  describe "index" do
    setup [:create_user]

    test "lists all challenges in admin panel", %{conn: conn} do
      conn = get(conn, admin_panel_challenges_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Challenges"
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
