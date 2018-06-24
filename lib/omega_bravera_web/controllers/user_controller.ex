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

    ngos = Fundraisers.get_ngos_by_user(user_id)

    render(conn, "causes.html", ngos: ngos)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

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

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

end
