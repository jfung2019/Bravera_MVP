defmodule OmegaBraveraWeb.DonationController do
  use OmegaBraveraWeb, :controller

  require Logger

  alias OmegaBravera.{Challenges, Accounts, StripeHelpers}
  alias OmegaBravera.Donations.{Pledges, Processor, Notifier}

  def index(conn, %{"ngo_chal_slug" => slug, "ngo_slug" => ngo_slug}) do
    challenge =
      Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [], team: [:user])

    case challenge do
      %Challenges.NGOChal{} = challenge ->
        donors =
          case challenge.type do
            "PER_KM" ->
              Accounts.latest_km_donors(challenge)

            "PER_MILESTONE" ->
              Accounts.latest_donors(challenge)
          end

        render(conn, "index.html", %{challenge: challenge, donors: donors})

      _ ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end

  def create(conn, %{
        "donation" => donation_params,
        "ngo_chal_slug" => ngo_chal_slug,
        "ngo_slug" => ngo_slug
      }) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, ngo_chal_slug, [:ngo, :user])
    stripe_customer = StripeHelpers.create_stripe_customer(donation_params)
    donor = Accounts.insert_or_return_email_donor(donation_params)
    challenge_path = ngo_ngo_chal_path(conn, :show, challenge.ngo.slug, challenge.slug)

    Accounts.create_or_update_donor_opt_in_mailing_list(donor, challenge.ngo, donation_params)

    donation_params =
      donation_params
      |> Map.put("donor_id", donor.id)
      |> Map.put("email", donor.email)

    case challenge.type do
      "PER_MILESTONE" ->
        result =
          case Pledges.create(
                 challenge,
                 stripe_customer,
                 donation_params
               ) do
            {:ok, pledges} ->
              Notifier.email_parties(challenge, donor, pledges)

              # TODO: kickstarter donation processing should be moved to a background process so we can have some fault tolerance - Simon
              kickstarter_processing_result =
                pledges
                |> Pledges.get_kickstarter()
                |> Processor.charge_donation()

              case kickstarter_processing_result do
                {:ok, _} -> :ok
                {:error, _} -> :error
              end

            {:error, _} ->
              :error
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

      "PER_KM" ->
        result =
          case Pledges.create(
                 challenge,
                 stripe_customer,
                 donation_params
               ) do
            {:ok, pledge} ->
              Notifier.email_parties(challenge, donor, pledge)
              :ok

            {:error, reason} ->
              Logger.info("Error creating km pledge: #{inspect(reason)}")
              :error
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
  end
end
