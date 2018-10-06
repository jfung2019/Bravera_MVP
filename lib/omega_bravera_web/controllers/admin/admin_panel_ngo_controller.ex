defmodule OmegaBraveraWeb.AdminPanelNGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Slugify
  alias OmegaBravera.Accounts

  plug(:assign_available_currencies when action in [:edit, :new])

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos_preload()
    render(conn, "index.html", ngos: ngos)
  end

  def show(conn, %{"slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug, :preload)
    render(conn, "show.html", ngo: ngo)
  end

  def new(conn, _params) do
    users = Accounts.list_users()
    changeset = Fundraisers.change_ngo(%NGO{})
    conn |> render("new.html", changeset: changeset, users: users)
  end

  def create(conn, %{"ngo" => ngo_params}) do
    sluggified_ngo_name = Slugify.gen_random_slug(ngo_params["name"])

    ngo_params =
      ngo_params
      |> Map.put("slug", sluggified_ngo_name)

    case Fundraisers.create_ngo(ngo_params) do
      {:ok, ngo} ->
        conn
        |> put_flash(:info, "NGO created successfully.")
        |> redirect(to: admin_panel_ngo_path(conn, :show, ngo))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users()

        conn
        |> assign_available_currencies(nil)
        |> render("new.html", changeset: changeset, users: users)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    ngo = slug |> Fundraisers.get_ngo_by_slug()
    users = Accounts.list_users()
    changeset = ngo |> Fundraisers.change_ngo()
    render(conn, "edit.html", ngo: ngo, users: users, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "ngo" => ngo_params}) do
    ngo = slug |> Fundraisers.get_ngo_by_slug()

    case Fundraisers.update_ngo(ngo, ngo_params) do
      {:ok, _ngo} ->
        conn
        |> put_flash(:info, "NGO updated successfully.")
        |> redirect(to: admin_panel_ngo_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        users = Accounts.list_users()

        conn
        |> assign_available_currencies(nil)
        |> render("edit.html", users: users, ngo: ngo, changeset: changeset)
    end
  end

  defp assign_available_currencies(conn, _opts),
    do: assign(conn, :available_currencies, Fundraisers.available_currencies())
end
