defmodule OmegaBraveraWeb.UserControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.Accounts

  @update_attrs %{
    firstname: "sherief",
    lastname: "Alaa",
    location_id: 1,
    setting: %{
      location: "US",
      weight_whole: "45",
      weight_fraction: "0.5",
      date_of_birth: "1980-07-14",
      gender: "Male"
    },
    credential: %{
      password: "testtest",
      password_confirmation: "testtest"
    }
  }
  @invalid_attrs %{email: nil, firstname: nil, lastname: nil}
  #  field(:location, :string)
  #  field(:weight, :decimal, default: nil)
  #  field(:date_of_birth, :date)
  #  field(:gender, :string, default: nil)

  setup %{conn: conn} do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: "user@example.com",
      password: "test1234",
      location_id: 1
    }

    with {:ok, user} <- Accounts.create_user(attrs),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token), user: user}
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    test "renders form for editing chosen user", %{conn: conn} do
      conn = get(conn, user_path(conn, :edit))
      assert html_response(conn, 200) =~ "Edit Account"
    end
  end

  describe "update user" do
    test "redirects when data is valid", %{conn: conn, user: %{id: user_id}} do
      conn = put(conn, user_path(conn, :update), user: @update_attrs)
      assert get_flash(conn, :info) =~ "Updated account settings successfully."
      assert redirected_to(conn) == user_path(conn, :edit)

      weight = Decimal.from_float(45.5)

      assert %{
               firstname: "sherief",
               lastname: "Alaa",
               location_id: 1,
               setting: %{
                 location: "US",
                 weight: ^weight,
                 date_of_birth: ~D[1980-07-14],
                 gender: "Male"
               },
               credential: %{password_hash: hash}
             } = Accounts.get_user!(user_id, [:setting, :credential])

      assert hash != nil
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = put(conn, user_path(conn, :update, %{"user" => @invalid_attrs}))

      assert html_response(conn, 200) =~
               "Oops, something went wrong! Please check the errors below."
    end
  end

  describe "email activation" do
    test "user activates email token, redirects when session has after_email_verify in session",
         %{conn: conn, user: user} do
      conn =
        conn
        |> bypass_through(OmegaBraveraWeb.Router, :browser)
        |> get("/")
        |> Plug.Conn.put_resp_cookie("after_email_verify", "/test",
          max_age: Application.get_env(:omega_bravera, :cookie_age)
        )
        |> send_resp(:ok, "")
        |> get(user_path(conn, :activate_email, user.email_activation_token))

      assert redirected_to(conn) == "/test"
    end
  end
end
