defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges
  alias OmegaBravera.Challenges.NGOChal

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, _params) do
    changeset = Challenges.change_ngo_chal(%NGOChal{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ngo_chal" => ngo_chal_params}) do
    case Challenges.create_ngo_chal(ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Ngo chal created successfully.")
        |> redirect(to: ngo_chal_path(conn, :show, ngo_chal))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    render(conn, "show.html", ngo_chal: ngo_chal)
  end

  def edit(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ngo_chal" => ngo_chal_params}) do
    ngo_chal = Challenges.get_ngo_chal!(id)

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Ngo chal updated successfully.")
        |> redirect(to: ngo_chal_path(conn, :show, ngo_chal))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    {:ok, _ngo_chal} = Challenges.delete_ngo_chal(ngo_chal)

    conn
    |> put_flash(:info, "Ngo chal deleted successfully.")
    |> redirect(to: ngo_chal_path(conn, :index))
  end
end
