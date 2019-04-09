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
    Offers.Notifier,
    Repo
  }

  plug :put_layout, false when action in [:qr_code]

  plug(:assign_available_options when action in [:create])
  plug OmegaBraveraWeb.UserEmailVerified when action in [:create, :new]

  @doc """
  Form for vendor that allows them to create redeems.
  """
  def new_redeem(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token
      }) do
    redeem_form_page(conn, offer_slug, slug, redeem_token)
  end

  @doc """
  Form for vendor that allows them to create redeems.

  TODO: remove redeem_form_page() and let new_redeem() handle rendering redeem forms. -Sherief
  """
  def qr_code(
        conn,
        %{
          "offer_challenge_slug" => slug,
          "offer_slug" => offer_slug,
          "redeem_token" => redeem_token
        } = params
      ) do
    if Map.has_key?(params, "redeem") do
      redeem_form_page(conn, offer_slug, slug, redeem_token)
    else
      send_qr_code(conn, params)
    end
  end

  defp redeem_form_page(conn, offer_slug, slug, redeem_token) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [
        :offer_redeems,
        :user,
        offer: [:offer_rewards, :offer_redeems]
      ])

    case offer_challenge do
      nil ->
        render_404(conn)

      _ ->
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
            render_404(conn)
        end
    end
  end

  @doc """
  Sends a QR code file in png.
  """
  def send_qr_code(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token
      }) do
    offer_challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug)

    if redeem_token == offer_challenge.redeem_token do
      qr_code_png =
        offer_offer_challenge_offer_challenge_url(
          conn,
          :new_redeem,
          offer_slug,
          slug,
          offer_challenge.redeem_token
        )
        |> EQRCode.encode()
        |> EQRCode.png()

      conn
      |> put_resp_content_type("image/png")
      |> put_resp_header("content-disposition", "attachment; filename=qr.png")
      |> send_resp(200, qr_code_png)
    else
      render_404(conn)
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
        offer: [:offer_rewards, :offer_redeems]
      ])

    vendor = Repo.get_by(OfferVendor, vendor_id: offer_redeem_params["vendor_id"])

    cond do
      !Enum.empty?(offer_challenge.offer_redeems) ->
        render(conn, "previously_redeemed.html",
          offer_challenge: offer_challenge,
          layout: {OmegaBraveraWeb.LayoutView, "app.html"}
        )

      # Make sure the vendor_id is in our database.
      is_nil(vendor) ->
        conn
        |> put_flash(:error, "Your Vendor ID seems to be incorrect.")
        |> redirect(
          to:
            offer_offer_challenge_offer_challenge_path(
              conn,
              :new_redeem,
              offer_slug,
              slug,
              redeem_token
            )
        )

      true ->
        case Offers.create_offer_redeems(offer_challenge, vendor, %{
               "offer_reward_id" => offer_redeem_params["offer_reward_id"]
             }) do
          {:ok, offer_redeem} ->
            Notifier.send_user_reward_redemption_successful(offer_challenge)

            #1091 #note-5
            if offer_redeem_params["send_vendor_confirmation_email"] == "true" do
              Notifier.send_reward_vendor_redemption_successful_confirmation(
                offer_challenge,
                offer_redeem
              )
            end

            conn
            |> render("redeem_sucessful.html",
              layout: {OmegaBraveraWeb.LayoutView, "app.html"},
              offer_challenge: offer_challenge
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> render("new_redeem.html",
              offer_challenge: offer_challenge,
              changeset: changeset,
              vendor_id: offer_redeem_params["vendor_id"],
              layout: {OmegaBraveraWeb.LayoutView, "app.html"}
            )
        end
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

    case Offers.create_offer_challenge(offer, current_user) do
      {:ok, offer_challenge} ->
        send_emails(offer_challenge)

        conn
        |> put_flash(:info, "Success! You have registered for this offer!")
        |> redirect(to: offer_offer_challenge_path(conn, :show, offer.slug, offer_challenge.slug))

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
        render_404(conn)

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

  defp send_emails(%OfferChallenge{status: status} = challenge) do
    case status do
      "pre_registration" ->
        Offers.Notifier.send_pre_registration_challenge_sign_up_email(challenge)

      _ ->
        Offers.Notifier.send_challenge_signup_email(challenge)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end
end
