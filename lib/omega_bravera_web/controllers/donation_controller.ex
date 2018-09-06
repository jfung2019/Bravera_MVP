require IEx
defmodule OmegaBraveraWeb.DonationController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Money, Money.Donation, Fundraisers, Challenges, Accounts, Stripe, StripeHelpers}
  alias OmegaBravera.Donations.Processor

# TODO Total Pledged logic in milestone generators

  def index(conn, _params) do
    donations = Money.list_donations()
    render(conn, "index.html", donations: donations)
  end

  def new(conn, _params) do
    changeset = Money.change_donation(%Donation{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"donation" => donation_params, "ngo_chal_slug" => ngo_chal_slug}) do
    # TODO re-implement the SECURED/PLEDGED LOGIC
    # TODO simplify kickstarter logic since all have kickstarter now

    # TODO change milestone logic to programmatically generate them based on one value

    milestones = create_milestone_map(donation_params)
    nc = Challenges.get_ngo_chal_by_slug(ngo_chal_slug)
    chal_user = Accounts.get_user!(nc.user_id)
    ngo = Fundraisers.get_ngo!(nc.ngo_id)
    stripe_customer = StripeHelpers.create_stripe_customer(donation_params)

    require IEx
    IEx.pry

    %{"str_src" => str_src, "currency" => currency, "email" => email} = donation_params

    current_user =
      cond do
        Guardian.Plug.current_resource(conn) ->
          Guardian.Plug.current_resource(conn)
        true ->
          Accounts.insert_or_return_email_user(email)
      end

    if donation_params["kickstarter"] do
      case Processor.handle_donation(current_user, ngo, nc, donation_params, stripe_customer, milestones) do
        {:ok, :donations_and_pledges_created} ->
          conn
          |> put_flash(:info, "Donations processed! Check your email for more information.")
          |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo.slug, nc.slug))
        {:error, :donation_model_couldnt_be_created} ->
          changeset = Money.change_donation(%Donation{})

          conn
          |> put_flash(:error, "There was an error on the form.")
          |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo.slug, ngo_chal_slug))
        {:error, :stripe_api_error}
          conn
          |> put_flash(:error, "Initial donation couldn't be processed.")
          |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo.slug, ngo_chal_slug))
      end
    else
      rel_params = %{user_id: current_user.id, ngo_chal_id: nc.id, ngo_id: nc.ngo_id}
      case Money.create_donations(rel_params, milestones, currency, str_src, stripe_customer["id"]) do
        {:ok, _response} ->
          conn
          |> put_flash(:info, "Donation created successfully.")
          |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo.slug, ngo_chal_slug))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :show, changeset: changeset)
      end
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
        |> redirect(to: user_path(conn, :donations, donation))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", donation: donation, changeset: changeset)
    end
  end

  defp create_milestone_map(donation_params) do
    cond do
      donation_params["milestone_4"] ->
        %{4 => donation_params["milestone_4"],3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_3"] ->
        %{3 => donation_params["milestone_3"],2 => donation_params["milestone_2"],1 => donation_params["milestone_1"]}
      donation_params["milestone_2"] ->
        %{2 => donation_params["milestone_2"], 1 => donation_params["milestone_1"]}
      donation_params["milestone_1"] ->
        %{1 => donation_params["milestone_1"]}
      true ->
        %{}
    end
  end

end
