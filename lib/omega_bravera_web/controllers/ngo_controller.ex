defmodule OmegaBraveraWeb.NGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Fundraisers.NGO

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos()
    render(conn, "index.html", ngos: ngos)
  end

  def new(conn, _params) do
    changeset = Fundraisers.change_ngo(%NGO{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ngo" => ngo_params}) do
    case Fundraisers.create_ngo(ngo_params) do
      {:ok, ngo} ->
        conn
        |> put_flash(:info, "Ngo created successfully.")
        |> redirect(to: ngo_path(conn, :show, ngo))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ngo = Fundraisers.get_ngo!(id)
    render(conn, "show.html", ngo: ngo)
  end

  def edit(conn, %{"id" => id}) do
    ngo = Fundraisers.get_ngo!(id)
    changeset = Fundraisers.change_ngo(ngo)
    render(conn, "edit.html", ngo: ngo, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ngo" => ngo_params}) do
    ngo = Fundraisers.get_ngo!(id)

    case Fundraisers.update_ngo(ngo, ngo_params) do
      {:ok, ngo} ->
        conn
        |> put_flash(:info, "Ngo updated successfully.")
        |> redirect(to: ngo_path(conn, :show, ngo))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ngo: ngo, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ngo = Fundraisers.get_ngo!(id)
    {:ok, _ngo} = Fundraisers.delete_ngo(ngo)

    conn
    |> put_flash(:info, "Ngo deleted successfully.")
    |> redirect(to: ngo_path(conn, :index))
  end
end
