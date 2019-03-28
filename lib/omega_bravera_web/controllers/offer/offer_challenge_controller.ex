defmodule OmegaBraveraWeb.Offer.OfferChallengeController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    Offers,
    Offers.OfferChallenge,
    Offers.OfferVendor,
    Fundraisers.NgoOptions,
    Repo,
    Slugify
  }

  plug :put_layout, false when action in [:qr_code]

  plug(:assign_available_options when action in [:create])
  plug OmegaBraveraWeb.UserEmailVerified when action in [:create, :new]

  @doc """
  Form for vendor that allows them to create redeems.
  """
  def qr_code(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token,
        "redeem" => _redeem
      }) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [
        :offer_redeems,
        :user,
        offer: [:offer_rewards]
      ])

    changeset = Offers.change_offer_redeems(%Offers.OfferRedeem{})

    cond do
      !Enum.empty?(offer_challenge.offer_redeems) ->
        render(conn, "previously_redeemed.html",
          offer_challenge: offer_challenge,
          layout: {OmegaBraveraWeb.LayoutView, "app.html"}
        )

      redeem_token == offer_challenge.redeem_token ->
        render(conn, "new_redeem.html",
          offer_challenge: offer_challenge,
          changeset: changeset,
          layout: {OmegaBraveraWeb.LayoutView, "app.html"}
        )

      true ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end

  @doc """
  Sends a QR code file in png.
  """
  def qr_code(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token
      }) do
    offer_challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug)

    if redeem_token == offer_challenge.redeem_token do
      qr_code_png =
        "#{Application.get_env(:omega_bravera, :app_base_url)}#{
          offer_offer_challenge_offer_challenge_path(
            conn,
            :qr_code,
            offer_slug,
            slug,
            offer_challenge.redeem_token,
            %{"redeem" => "true"}
          )
        }"
        |> EQRCode.encode()
        |> EQRCode.png()

      conn
      |> put_resp_content_type("image/png")
      |> put_resp_header("content-disposition", "attachment; filename=qr.png")
      |> send_resp(200, qr_code_png)
    else
      conn
      |> put_view(OmegaBraveraWeb.PageView)
      |> put_status(:not_found)
      |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})
    end
  end

  def save_redeem(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token,
        "offer_redeem" => offer_redeem_params
      }) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [
        :offer_redeems,
        :user,
        offer: [:offer_rewards]
      ])

    vendor = Repo.get_by(OfferVendor, vendor_id: offer_redeem_params["vendor_id"])

    # Make sure the vendor_id is in our database.
    if is_nil(vendor) do
      conn
      |> put_flash(:error, "Your Vendor ID seems to be incorrect.")
      |> redirect(
        to:
          offer_offer_challenge_offer_challenge_path(
            conn,
            :qr_code,
            offer_slug,
            slug,
            redeem_token,
            %{"redeem" => "true"}
          )
      )
    end

    case Offers.create_offer_redeems(offer_challenge, vendor, %{
           "offer_reward_id" => offer_redeem_params["offer_reward_id"]
         }) do
      {:ok, _offer_redeem} ->
        conn
        |> render("redeem_sucessful.html", layout: {OmegaBraveraWeb.LayoutView, "app.html"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("new_redeem.html",
          offer_challenge: offer_challenge,
          changeset: changeset,
          layout: {OmegaBraveraWeb.LayoutView, "app.html"}
        )
    end
  end

  def new(conn, params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        render(conn, "login_onboarding.html",
          offer: Offers.get_offer_by_slug(params["offer_slug"])
        )

      _user ->
        create(conn, params)
    end
  end

  def create(conn, %{"offer_slug" => offer_slug}) do
    current_user =
      Guardian.Plug.current_resource(conn)
      |> Repo.preload(:offer_challenges)

    offer = Offers.get_offer_by_slug(offer_slug)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    attrs = %{
      "user_id" => current_user.id,
      "slug" => sluggified_username
    }

    case Offers.create_offer_challenge(offer, current_user, attrs) do
      {:ok, offer_challenge} ->
        offer_challenge_path =
          offer_offer_challenge_path(conn, :show, offer.slug, sluggified_username)

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
    offer_challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug, user: [:strava], offer: [])

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
