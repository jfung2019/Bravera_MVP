defmodule OmegaBraveraWeb.DonationController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Money, Money.Donation, Fundraisers, Challenges, Accounts, Stripe, StripeHelpers}
  alias OmegaBravera.Donations.{Pledges, Processor, Notifier}

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
    challenge = Challenges.get_ngo_chal_by_slug(ngo_chal_slug)
    stripe_customer = StripeHelpers.create_stripe_customer(donation_params)
    donor = get_current_user(conn, donation_params)

    challenge_path = ngo_ngo_chal_path(conn, :show, challenge.ngo.slug, challenge.slug)

    result = case Pledges.create(challenge, stripe_customer, Map.put(donation_params, "donor_id", donor.id)) do
               {:ok, pledges} ->
                 Notifier.email_parties(challenge, donor, pledges, challenge_path)

                 #TODO: kickstarter donation processing should be moved to a background process so we can have some fault tolerance - Simon
                 kickstarter_processing_result =
                   pledges
                   |> Pledges.get_kickstarter()
                   |> Processor.charge_donation()

                 case kickstarter_processing_result do
                   {:ok, _} -> :ok
                   {:error, _} -> :error
                 end
               {:error, _} -> :error
             end

    case result do
      :ok ->
        conn
        |> put_flash(:info, "Donations pledged! Check your email for more information.")
        |> redirect(to: challenge_path)
      :error ->
        conn
        |> put_flash(:error, "Initial donation and/or pledges couldn't be processed.")
        |> redirect(to: challenge_path)
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

  defp get_current_user(conn, params) do
    Accounts.insert_or_return_email_user(params)
  end
end
