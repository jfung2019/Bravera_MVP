defmodule OmegaBraveraWeb.Offer.OfferChallengeController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    Offers.OfferChallenge,
    Offers,
    Fundraisers.NgoOptions,
    Slugify
  }

  plug(:assign_available_options when action in [:create])

  plug :put_layout, false when action in [:qr_code]

  def qr_code(conn, %{"offer_challenge_slug" => slug, "offer_slug" => offer_slug, "redeem_token" => redeem_token}) do
    offer_challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug)

    if redeem_token == offer_challenge.redeem_token do
      render(conn, "qr_code.html", offer_challenge: offer_challenge)
    else
      render(conn, "404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end

  def new(conn, params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        render(conn, "login_onboarding.html", offer: Offers.get_offer_by_slug(params["offer_slug"]))
      _user ->
        create(conn, params)
    end
  end

  def create(conn, %{"offer_slug" => offer_slug}) do
    current_user = Guardian.Plug.current_resource(conn)
    offer = Offers.get_offer_by_slug(offer_slug)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    attrs = %{
      "user_id" => current_user.id,
      "slug" => sluggified_username
    }

    case Offers.create_offer_challenge(offer, attrs) do
      {:ok, offer_challenge} ->
        offer_challenge_path = offer_offer_challenge_path(conn, :show, offer.slug, sluggified_username)
        send_emails(offer_challenge, offer_challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for this offer!")
        |> redirect(to: offer_challenge_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Could not sign up user for offer. Reason: #{inspect(changeset)}")

        conn
        |> put_flash(:error, "You cannot signup for an offer twice.")
        |> redirect(to: offer_path(conn, :index))
    end
  end

  def show(conn, %{"offer_slug" => offer_slug, "slug" => slug}) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [user: [:strava], offer: []])

    case offer_challenge do
      nil ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      offer_challenge ->
        render_attrs = get_render_attrs(conn, offer_challenge, offer_slug)
        render(conn, "show.html", render_attrs)
    end
  end

  defp get_render_attrs(conn, %OfferChallenge{type: "PER_MILESTONE"} = challenge, offer_slug) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      offer_with_stats: Offers.get_offer_with_stats(offer_slug),
      m_targets: OfferChallenge.milestones_distances(challenge)
    }
  end

  defp get_render_attrs(conn, %OfferChallenge{type: "PER_KM"} = challenge, offer_slug) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      offer_with_stats: Offers.get_offer_with_stats(offer_slug)
    }
  end

  defp send_emails(%OfferChallenge{status: status} = challenge, challenge_path) do
    case status do
      "pre_registration" ->
        Offers.Notifier.send_pre_registration_challenge_sign_up_email(
          challenge,
          challenge_path
        )

      _ ->
        Offers.Notifier.send_challenge_signup_email(challenge, challenge_path)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end
end
