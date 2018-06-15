defmodule OmegaBraveraWeb.DonationController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Money
  alias OmegaBravera.Money.Donation

  def index(conn, _params) do
    donations = Money.list_donations()
    render(conn, "index.html", donations: donations)
  end

  def new(conn, _params) do
    changeset = Money.change_donation(%Donation{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"donation" => donation_params}) do
    case Money.create_donation(donation_params) do
      {:ok, donation} ->
        conn
        |> put_flash(:info, "Donation created successfully.")
        |> redirect(to: donation_path(conn, :show, donation))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    donation = Money.get_donation!(id)
    render(conn, "show.html", donation: donation)
  end

  def edit(conn, %{"id" => id}) do
    donation = Money.get_donation!(id)
    changeset = Money.change_donation(donation)
    render(conn, "edit.html", donation: donation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "donation" => donation_params}) do
    donation = Money.get_donation!(id)

    case Money.update_donation(donation, donation_params) do
      {:ok, donation} ->
        conn
        |> put_flash(:info, "Donation updated successfully.")
        |> redirect(to: donation_path(conn, :show, donation))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", donation: donation, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    donation = Money.get_donation!(id)
    {:ok, _donation} = Money.delete_donation(donation)

    conn
    |> put_flash(:info, "Donation deleted successfully.")
    |> redirect(to: donation_path(conn, :index))
  end
end
