defmodule OmegaBraveraWeb.Offer.OfferChallengeController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    # Accounts,
    Offers.OfferChallenge,
    Offers.Offer,
    Offers,
    Fundraisers.NgoOptions,
    Slugify
    # Accounts.User
  }

  plug(:assign_available_options when action in [:create])

  def create(conn, params) do
    case Guardian.Plug.current_resource(conn)do
      nil ->
        conn
        |> put_flash(:error, "Please login first")
        |> redirect(to: page_path(conn, :login))

      user -> create(conn, params, user)
    end
  end

  def create(conn, %{"offer_slug" => offer_slug}, current_user) do
    offer = Offers.get_offer_by_slug(offer_slug)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    attrs = %{
      "user_id" => current_user.id,
      "slug" => sluggified_username
    }

    case create_offer_challenge(offer, attrs) do
      {:ok, _offer_challenge} ->
        offer_challenge_path = offer_offer_challenge_path(conn, :show, offer.slug, sluggified_username)
        # TODO: waiting for templates from Alyn -Sherief
        #send_emails(offer_challenge, offer_challenge_path)

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
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [user: [:strava], ngo: []])

    case offer_challenge do
      nil ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      offer_challenge ->
        render_attrs = get_render_attrs(conn, offer_challenge, offer_slug)
        # TODO: Work on helpers.ex's get_stats to match Offers structs..
        render(conn, "show.html", Map.merge(render_attrs, get_stats(offer_challenge)))
    end
  end

  # def invite_buddies(conn, %{
  #       "ngo_chal_slug" => slug,
  #       "ngo_slug" => ngo_slug,
  #       "buddies" => buddies
  #     }) do
  #   challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo])

  #   Challenges.Notifier.send_buddies_invite_email(challenge, Map.values(buddies))
  #   redirect(conn, to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
  # end


  defp get_render_attrs(conn, %OfferChallenge{type: "PER_MILESTONE"} = challenge, offer_slug) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      offer_with_stats: Offers.get_offer_with_stats(offer_slug),
      m_targets: OfferChallenge.milestones_distances(challenge),
      stats: get_stats(challenge)
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

  # TODO: support teams
  defp create_offer_challenge(%Offer{} = offer, attrs) do
    if offer.additional_members > 0 do
      nil
      # Challenges.create_ngo_chal_with_team(%NGOChal{}, ngo, attrs)
    else
      Offers.create_offer_challenge(offer, attrs)
    end
  end

  # TODO:
  # defp send_emails(%NGOChal{status: status} = challenge, challenge_path) do
  #   case status do
  #     "pre_registration" ->
  #       Challenges.Notifier.send_pre_registration_challenge_sign_up_email(
  #         challenge,
  #         challenge_path
  #       )

  #     _ ->
  #       Challenges.Notifier.send_challenge_signup_email(challenge, challenge_path)
  #   end
  # end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end
end
