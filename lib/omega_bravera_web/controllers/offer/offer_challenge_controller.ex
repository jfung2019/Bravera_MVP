defmodule OmegaBraveraWeb.Offer.OfferChallengeController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    Accounts,
    Offers.OfferChallenge,
    Offers.Offer,
    Offers,
    Fundraisers.NgoOptions,
    Slugify,
    Accounts.User
  }

  plug(:assign_available_options when action in [:create])

  def create(conn, %{"offer_slug" => offer_slug}) do
    current_user = Guardian.Plug.current_resource(conn)
    offer = Offers.get_offer_by_slug(offer_slug)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    # TODO: Team support if offer.additional_members is > 0. team_name should the slug.
    # offer_chal_params =
    #   case Map.has_key?(chal_params, "team") do
    #     true -> put_in(chal_params, ["team", "user_id"], current_user.id)
    #     false -> offer_chal_params
    #   end

    create_offer_challenge_params = %{
      "user_id" => current_user.id,
      "offer_slug" => offer_slug,
      "offer_id" => offer.id,
      "slug" => sluggified_username,
      "default_currency" => offer.currency,
      "type" => hd(offer.offer_challenge_types),
      "activity_type" => hd(offer.activities),
      "distance_target" => hd(offer.distances),
      "duration" => hd(offer.duration)
    }

    case create_offer_challenge(offer, create_offer_challenge_params) do
      {:ok, offer_challenge} ->
        offer_challenge_path = offer_offer_challenge_path(conn, :show, offer.slug, sluggified_username)
        send_emails(offer_challenge, offer_challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for this offer!")
        |> redirect(to: offer_challenge_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Could not sign up user for offer. Reason: #{inspect(changeset)}")

        conn
        |> put_flash(:error, "Something went wrong while signing you up to this offer.")
        |> redirect(to: offer_path(conn, :index))
    end
  end

  # TODO:
  # def show(conn, %{"ngo_slug" => ngo_slug, "slug" => slug}) do
  #   challenge =
  #     Challenges.get_ngo_chal_by_slugs(ngo_slug, slug,
  #       user: [:strava],
  #       ngo: [],
  #       team: [users: [:strava], invitations: []]
  #     )

  #   case challenge do
  #     nil ->
  #       conn
  #       |> put_view(OmegaBraveraWeb.PageView)
  #       |> put_status(:not_found)
  #       |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

  #     challenge ->
  #       render_attrs = get_render_attrs(conn, challenge, ngo_slug)

  #       render(conn, "show.html", Map.merge(render_attrs, get_stats(challenge)))
  #   end
  # end

  # def invite_buddies(conn, %{
  #       "ngo_chal_slug" => slug,
  #       "ngo_slug" => ngo_slug,
  #       "buddies" => buddies
  #     }) do
  #   challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo])

  #   Challenges.Notifier.send_buddies_invite_email(challenge, Map.values(buddies))
  #   redirect(conn, to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
  # end


  # defp get_render_attrs(conn, %OfferChallenge{type: "PER_MILESTONE"} = challenge, changeset, ngo_slug) do
  #   %{
  #     challenge: challenge,
  #     m_targets: NGOChal.milestones_distances(challenge),
  #     changeset: changeset,
  #     stats: get_stats(challenge),
  #     activities: Challenges.latest_activities(challenge, 5),
  #     current_user: Guardian.Plug.current_resource(conn),
  #     ngo_with_stats: Fundraisers.get_ngo_with_stats(ngo_slug)
  #   }
  # end

  # defp get_render_attrs(conn, %OfferChallenge{type: "PER_KM"} = challenge, changeset, ngo_slug) do
  #   %{
  #     challenge: challenge,
  #     changeset: changeset,
  #     activities: Challenges.latest_activities(challenge, 5),
  #     current_user: Guardian.Plug.current_resource(conn),
  #     total_pledges_per_km: Challenges.get_per_km_challenge_total_pledges(challenge.slug),
  #     ngo_with_stats: Fundraisers.get_ngo_with_stats(ngo_slug)
  #   }
  # end

  # TODO:
  # defp create_offer_challenge(%Offer{} = offer, attrs) do
  #   case attrs["has_team"] do
  #     "true" ->
  #       Challenges.create_ngo_chal_with_team(%NGOChal{}, ngo, attrs)

  #     _ ->
  #       Challenges.create_ngo_chal(%NGOChal{}, ngo, attrs)
  #   end
  # end

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
