defmodule OmegaBraveraWeb.UserController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Money, Fundraisers}
  alias OmegaBravera.Accounts.User

  def dashboard(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    render(conn, "dashboard.html", user: user)
  end

  def user_donations(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    %{id: user_id} = user

    donations = Money.get_donations_by_user(user_id)

    render(conn, "user_donations.html", donations: donations)
  end

  def ngos(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    %{id: user_id} = user

    ngos = Fundraisers.get_ngos_by_user(user_id)

    render(conn, "causes.html", ngos: ngos)
  end

  # Not used
  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  # Not used
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "show.html", user: user)
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: user_path(conn, :show, %{}))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end
