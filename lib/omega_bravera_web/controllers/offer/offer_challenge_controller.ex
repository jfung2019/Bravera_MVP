defmodule OmegaBraveraWeb.Offer.OfferChallengeController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    Offers,
    Offers.OfferChallenge,
    Offers.OfferRedeem,
    Offers.OfferVendor,
    Fundraisers.NgoOptions,
    Offers.Notifier,
    Repo,
    Accounts.User,
    Accounts
  }

  alias OmegaBraveraWeb.Offer.OfferChallengeHelper

  plug :put_layout, false when action in [:qr_code]

  plug :assign_available_options when action in [:create]
  plug OmegaBraveraWeb.ConnectTracker when action in [:create, :new, :add_team_member]
  plug OmegaBraveraWeb.UserEmailVerified when action in [:create, :new, :add_team_member]

  @doc """
  Form for vendor that allows them to create redeems.
  """
  def new_redeem(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => redeem_token
      }) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [
        :offer_redeems,
        :user,
        [:team, :offer_redeems, offer: [:offer_redeems]]
      ])

    offer_redeem = Repo.get_by(OfferRedeem, token: redeem_token)

    cond do
      is_nil(offer_redeem) or is_nil(offer_challenge) ->
        Logger.info(
          "OfferChallengeController.new_redeem: Redeem or OfferChallenge not found, will render 404."
        )

        render_404(conn)

      offer_redeem.status == "redeemed" ->
        render(conn, "previously_redeemed.html", layout: {OmegaBraveraWeb.LayoutView, "app.html"})

      offer_redeem.offer_challenge_id == offer_challenge.id ->
        changeset = Offers.change_offer_redeems(%OfferRedeem{})

        offer_rewards = Offers.list_offer_rewards_by_offer_id(offer_challenge.offer.id)

        offer_challenge =
          Map.put(
            offer_challenge,
            :offer,
            Map.put(offer_challenge.offer, :offer_rewards, offer_rewards)
          )

        render(conn, "new_redeem.html",
          offer_challenge: offer_challenge,
          offer_redeem: offer_redeem,
          redeems_count:
            Offers.get_offer_completed_redeems_count_by_offer_id(offer_challenge.offer_id),
          changeset: changeset,
          layout: {OmegaBraveraWeb.LayoutView, "app.html"}
        )

      true ->
        render_404(conn)
    end
  end

  @doc """
  Sends a QR code file in png.
  """
  def send_qr_code(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "redeem_token" => _redeem_token
      }) do
    offer_challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug)

    offer_redeem =
      Repo.get_by(OfferRedeem,
        user_id: offer_challenge.user_id,
        offer_challenge_id: offer_challenge.id
      )

    cond do
      is_nil(offer_challenge) ->
        render_404(conn)

      is_nil(offer_redeem) ->
        Logger.error(
          "OfferChallengeController.send_qr_code: Redeem for challenge #{
            inspect(offer_challenge.id)
          } not found, will render 404."
        )

        render_404(conn)

      offer_redeem.offer_challenge_id == offer_challenge.id ->
        qr_code_png =
          Routes.offer_offer_challenge_offer_challenge_url(
            conn,
            :new_redeem,
            offer_slug,
            slug,
            offer_redeem.token
          )
          |> EQRCode.encode()
          |> EQRCode.png()

        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("content-disposition", "attachment; filename=qr.png")
        |> send_resp(200, qr_code_png)

      true ->
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
        [:team, :offer_redeems, offer: [:offer_rewards, :offer_redeems]]
      ])

    offer_redeem = Repo.get_by(OfferRedeem, token: redeem_token)
    vendor = Repo.get_by(OfferVendor, vendor_id: offer_redeem_params["vendor_id"])

    case Offers.update_offer_redeems(
           offer_redeem,
           offer_challenge,
           offer_challenge.offer,
           vendor,
           offer_redeem_params
         ) do
      {:ok, offer_redeem} ->
        offer_redeem = Repo.preload(offer_redeem, :user)

        # Give back 25 points.
        OmegaBravera.Points.create_bonus_points(%{
          user_id: offer_redeem.user.id,
          source: "redeem",
          value: OmegaBravera.Points.Point.get_redeem_back_points()
        })

        user_with_points = Accounts.get_user_with_points(offer_redeem.user.id)
        Notifier.send_user_reward_redemption_successful(offer_challenge, user_with_points)

        Notifier.send_reward_vendor_redemption_successful_confirmation(
          offer_challenge,
          offer_redeem
        )

        conn
        |> render("redeem_sucessful.html",
          layout: {OmegaBraveraWeb.LayoutView, "app.html"},
          offer_challenge: offer_challenge,
          redeems_count:
            Offers.get_offer_completed_redeems_count_by_offer_id(offer_challenge.offer_id)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        if not is_nil(offer_challenge) do
          conn
          |> render("new_redeem.html",
            offer_challenge: offer_challenge,
            offer_redeem: offer_redeem,
            redeems_count:
              Offers.get_offer_completed_redeems_count_by_offer_id(offer_challenge.offer_id),
            changeset: changeset,
            vendor_id: offer_redeem_params["vendor_id"],
            layout: {OmegaBraveraWeb.LayoutView, "app.html"}
          )
        else
          render_404(conn)
        end
    end
  end

  def new(conn, params) do
    render(conn, "new.html",
      offer:
        Offers.get_offer_by_slug(params["offer_slug"],
          offer_challenges: [user: [:strava], team: [users: [:strava]]]
        ),
      offer_challenge_changeset: Offers.change_offer_challenge(%OfferChallenge{}),
      current_user: Guardian.Plug.current_resource(conn)
    )
  end

  def create(conn, %{"offer_slug" => offer_slug} = attrs) do
    offer_challenge_attrs =
      if Map.has_key?(attrs, "offer_challenge") do
        Map.merge(%{"team" => %{}, "offer_redeems" => [%{}]}, attrs["offer_challenge"])
      else
        %{"team" => %{}, "offer_redeems" => [%{}]}
      end

    current_user =
      Guardian.Plug.current_resource(conn)
      |> Repo.preload(:offer_challenges)

    offer = Offers.get_offer_by_slug(offer_slug)

    case offer do
      nil ->
        render_404(conn)

      offer ->
        case Offers.create_offer_challenge(offer, current_user, offer_challenge_attrs) do
          {:ok, offer_challenge} ->
            OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))

            conn
            |> put_flash(:info, gettext("Success! You have registered for this offer!"))
            |> put_session("created_offer_challenge", true)
            |> redirect(
              to: Routes.offer_offer_challenge_path(conn, :show, offer.slug, offer_challenge.slug)
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            Logger.info("Could not sign up user for offer. Reason: #{inspect(changeset)}")

            conn
            |> put_session("could_not_create_offer_challenge", true)
            |> redirect(to: Routes.offer_path(conn, :index))
        end
    end
  end

  def show(conn, %{"offer_slug" => offer_slug, "slug" => slug}) do
    offer_challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, [
        :offer_challenge_activities,
        :offer_redeems,
        user: [:strava],
        team: [users: [:strava], invitations: []],
        offer: []
      ])

    case offer_challenge do
      nil ->
        render_404(conn)

      offer_challenge ->
        render_attrs = get_render_attrs(conn, offer_challenge, offer_slug)

        conn
        |> open_welcome_modal()
        |> open_success_modal()
        |> open_signup_or_login_modal()
        |> render("show.html", render_attrs)
    end
  end

  def kick_team_member(conn, %{
        "offer_slug" => offer_slug,
        "offer_challenge_slug" => slug,
        "user_id" => team_member_user_id
      }) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_flash(
          :error,
          "Invalid operation. Please make sure you are using the correct account."
        )
        |> redirect(to: Routes.page_path(conn, :login))

      logged_in_challenge_owner ->
        challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug, [:user, team: [:users]])
        team_member = Offers.get_team_member(team_member_user_id, challenge.team.id)

        case Offers.kick_team_member(team_member, challenge, logged_in_challenge_owner) do
          {:ok, _struct} ->
            conn
            |> put_flash(:info, "Removed team member sucessfully!")
            |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))

          {:error, reason} ->
            Logger.error("Could not remove team member, reason: #{inspect(reason)}")

            conn
            |> put_flash(:error, "Could not remove team member.")
            |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))
        end
    end
  end

  def add_team_member(conn, %{
        "offer_slug" => offer_slug,
        "offer_challenge_slug" => slug,
        "invitation_token" => invitation_token
      }) do
    case Offers.get_offer_chal_by_slugs(offer_slug, slug, [:team, :user, offer: [:vendor]]) do
      nil ->
        conn
        |> put_flash(
          :info,
          "Challenge not found. Please make sure you clicked the correct link."
        )
        |> redirect(to: Routes.ngo_path(conn, :index))

      challenge ->
        case Guardian.Plug.current_resource(conn) do
          nil ->
            conn
            |> put_flash(
              :info,
              "Please login using Strava first then click the invitation link again from your email."
            )
            |> put_session("open_login_or_sign_up_to_join_team_modal", true)
            |> put_session("add_team_member_url", conn.request_path)
            |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))

          user ->
            # TODO: allow to fail gracefully when not found and passed to changeset. -Sherief
            invitation = Offers.get_team_member_invitation_by_token(invitation_token)

            case Offers.add_user_to_team(invitation, challenge.team, user, challenge.user) do
              {:ok, _} ->
                # TODO cast_assoc this add_user_to_team? -Sherief
                Offers.accepted_team_member_invitation(invitation)

                # TODO: cast_assoc with add_user_to_team. -Sherief
                case Offers.create_offer_redeems(challenge, challenge.offer.vendor, %{}, user) do
                  {:ok, _} ->
                    # Notifications
                    Offers.Notifier.send_team_owner_member_added_notification(challenge, user)
                    Offers.Notifier.send_challenge_signup_email(challenge, user)

                  {:error, reason} ->
                    Logger.info(
                      "OfferChallengeController: could not create redeem, reason: #{
                        inspect(reason.errors)
                      }"
                    )
                end

                conn
                |> put_flash(
                  :info,
                  "You are now part of #{inspect(User.full_name(challenge.user))} team."
                )
                |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))

              {:error, reason} ->
                Logger.info(
                  "OfferChallengeController: add team member to team, reason: #{
                    inspect(reason.errors)
                  }"
                )

                conn
                |> put_flash(
                  :error,
                  "Something went wrong, please make sure you are logged in and clicked your link in your invitation email."
                )
                |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))
            end
        end
    end
  end

  def invite_team_members(conn, %{
        "offer_challenge_slug" => slug,
        "offer_slug" => offer_slug,
        "team_members" => team_members
      }) do
    challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug, [:user, :offer, :team])

    # Maybe we should verify if the request is coming from the owner of the challenge. -Sherief
    Enum.map(Map.values(team_members), fn team_member ->
      case Offers.create_team_member_invitation(challenge.team, team_member) do
        {:ok, created_team_member} ->
          Offers.Notifier.send_team_members_invite_email(challenge, created_team_member)

        {:error, reason} ->
          Logger.info(
            "OfferChallengeController: Could not invite team member, reason: #{inspect(reason)}"
          )
      end
    end)

    # Maybe show errors to users instead of logging them only. -Sherief
    conn
    |> put_flash(:info, "Sucessfully invited your team member(s)!")
    |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))
  end

  def resend_invitation(conn, %{
        "offer_slug" => offer_slug,
        "offer_challenge_slug" => slug,
        "invitation_token" => invitation_token
      }) do
    current_user = Guardian.Plug.current_resource(conn)
    challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug, [:team, :user, :offer])
    invitation = Offers.get_team_member_invitation_by_token(invitation_token)

    case Offers.resend_team_member_invitation(invitation, current_user, challenge.user) do
      {:ok, updated_invitation} ->
        Offers.Notifier.send_team_members_invite_email(challenge, updated_invitation)

        conn
        |> put_flash(:info, "Resent invite to #{updated_invitation.invitee_name}!")
        |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))

      {:error, reason} ->
        Logger.info(
          "OfferChallengeController: could not resend invite, reason: #{inspect(reason.errors)}"
        )

        conn
        |> put_flash(:error, "Action not allowed.")
        |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))
    end
  end

  def cancel_invitation(conn, %{
        "offer_slug" => offer_slug,
        "offer_challenge_slug" => slug,
        "invitation_token" => invitation_token
      }) do
    current_user = Guardian.Plug.current_resource(conn)
    challenge = Offers.get_offer_chal_by_slugs(offer_slug, slug, [:team, :user, :offer])
    invitation = Offers.get_team_member_invitation_by_token(invitation_token)

    case Offers.cancel_team_member_invitation(invitation, current_user, challenge.user) do
      {:ok, _updated_invitation} ->
        conn
        |> put_flash(:info, "Invitation canceled.")
        |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))

      {:error, reason} ->
        Logger.info(
          "OfferChallengeController: could not cancel invite, reason: #{inspect(reason.errors)}"
        )

        conn
        |> put_flash(:error, "Action not allowed.")
        |> redirect(to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug))
    end
  end

  defp get_render_attrs(conn, %OfferChallenge{type: "PER_MILESTONE"} = challenge, offer_slug) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      offer:
        Offers.get_offer_by_slug(offer_slug,
          offer_challenges: [user: [:strava], team: [users: [:strava]]]
        ),
      m_targets: OfferChallenge.milestones_distances(challenge)
    }
  end

  defp get_render_attrs(
         conn,
         %OfferChallenge{has_team: true} = challenge,
         offer_slug
       ) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      all_team_members_activities_totals:
        Offers.get_team_member_activity_totals(
          challenge.id,
          [challenge.user] ++ challenge.team.users
        ),
      current_user: Guardian.Plug.current_resource(conn),
      offer:
        Offers.get_offer_by_slug(offer_slug,
          offer_challenges: [user: [:strava], team: [users: [:strava]]]
        )
    }
  end

  defp get_render_attrs(
         conn,
         %OfferChallenge{has_team: false} = challenge,
         offer_slug
       ) do
    %{
      challenge: challenge,
      activities: Offers.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      offer:
        Offers.get_offer_by_slug(offer_slug,
          offer_challenges: [user: [:strava], team: [users: [:strava]]]
        )
    }
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end

  defp open_success_modal(conn) do
    if is_nil(Plug.Conn.get_session(conn, "created_offer_challenge")) do
      conn
    else
      conn
      |> Plug.Conn.delete_session("created_offer_challenge")
      |> Plug.Conn.assign(:created_offer_challenge, true)
    end
  end
end
