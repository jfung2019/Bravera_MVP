defmodule OmegaBraveraWeb.AdminPanelNGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Slugify
  alias OmegaBravera.Accounts

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
    current_user = Guardian.Plug.current_resource(conn)
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
        render(conn, "new.html", changeset: changeset, users: users)
    end
  end
end
