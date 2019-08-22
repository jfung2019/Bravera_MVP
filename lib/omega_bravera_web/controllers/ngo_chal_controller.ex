defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  require Logger

  alias OmegaBravera.{
    Accounts,
    Challenges,
    Challenges.NGOChal,
    Fundraisers,
    Money,
    Fundraisers.NGO,
    Fundraisers.NgoOptions,
    Money.Donation,
    Accounts.User
  }

  plug(:assign_available_options when action in [:new, :edit, :create])
  plug OmegaBraveraWeb.UserEmailVerified when action in [:create, :new]
  plug OmegaBraveraWeb.ConnectTracker when action in [:create, :new]

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, %{"ngo_slug" => ngo_slug}) do
    case Fundraisers.get_ngo_with_stats(ngo_slug,
           ngo_chals: [user: [:strava], team: [users: [:strava]]]
         ) do
      nil ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      ngo ->
        current_user = Guardian.Plug.current_resource(conn)
        changeset = Challenges.change_ngo_chal(%NGOChal{}, %User{})

        render(conn, "new.html", changeset: changeset, ngo: ngo, current_user: current_user)
    end
  end

  def create(conn, %{"ngo_slug" => ngo_slug, "ngo_chal" => chal_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    ngo = Fundraisers.get_ngo_by_slug(ngo_slug)

    chal_params =
      case Map.has_key?(chal_params, "team") do
        true -> put_in(chal_params, ["team", "user_id"], current_user.id)
        false -> chal_params
      end

    extra_params = %{
      "user_id" => current_user.id,
      "ngo_slug" => ngo_slug,
      "ngo_id" => ngo.id,
      "default_currency" => ngo.currency
    }

    changeset_params = Map.merge(chal_params, extra_params)

    case create_challenge(ngo, current_user, changeset_params) do
      {:ok, challenge} ->
        send_emails(challenge)

        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo.slug, challenge.slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("new.html",
          changeset: changeset,
          ngo: ngo,
          current_user: Guardian.Plug.current_resource(conn)
        )
    end
  end

  def show(conn, %{"ngo_slug" => ngo_slug, "slug" => slug}) do
    challenge =
      Challenges.get_ngo_chal_by_slugs(ngo_slug, slug,
        user: [:strava],
        ngo: [],
        team: [users: [:strava], invitations: []]
      )

    case challenge do
      nil ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      challenge ->
        changeset = Money.change_donation(%Donation{currency: challenge.default_currency})

        render_attrs = get_render_attrs(conn, challenge, changeset, ngo_slug)

        conn
        |> open_welcome_modal()
        |> open_signup_or_login_modal()
        |> render("show.html", Map.merge(render_attrs, get_stats(challenge)))
    end
  end

  def invite_buddies(conn, %{
        "ngo_chal_slug" => slug,
        "ngo_slug" => ngo_slug,
        "buddies" => buddies
      }) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo])

    Challenges.Notifier.send_buddies_invite_email(challenge, Map.values(buddies))
    redirect(conn, to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
  end

  def invite_team_members(conn, %{
        "ngo_chal_slug" => slug,
        "ngo_slug" => ngo_slug,
        "team_members" => team_members
      }) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo, :team])

    Enum.map(Map.values(team_members), fn team_member ->
      case Challenges.create_team_member_invitation(challenge.team, team_member) do
        {:ok, created_team_member} ->
          # Send invitation
          Challenges.Notifier.send_team_members_invite_email(challenge, created_team_member)

        {:error, reason} ->
          Logger.info("Could not invite team member, reason: #{inspect(reason)}")
      end
    end)

    conn
    |> put_flash(:info, "Sucessfully invited your team member(s)!")
    |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
  end

  def resend_invitation(conn, %{
        "ngo_slug" => ngo_slug,
        "ngo_chal_slug" => slug,
        "invitation_token" => invitation_token
      }) do
    current_user = Guardian.Plug.current_resource(conn)
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:team, :user, :ngo])
    invitation = Challenges.get_team_member_invitation_by_token(invitation_token)

    # Make sure the user has the permission and whether the invite was recently sent or not.
    if current_user.id == challenge.user.id and
         Timex.before?(Timex.now(), Timex.shift(invitation.updated_at, days: 1)) do
      Challenges.Notifier.send_team_members_invite_email(challenge, invitation)

      # Remember when was the last email was sent
      Challenges.resend_team_member_invitation(invitation)

      conn
      |> put_flash(:info, "Resent invite to #{invitation.invitee_name}!")
      |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
    else
      conn
      |> put_flash(:error, "Action not allowed.")
      |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
    end
  end

  def cancel_invitation(conn, %{
        "ngo_slug" => ngo_slug,
        "ngo_chal_slug" => slug,
        "invitation_token" => invitation_token
      }) do
    current_user = Guardian.Plug.current_resource(conn)
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:team, :user, :ngo])

    if current_user.id == challenge.user.id do
      Challenges.get_team_member_invitation_by_token(invitation_token)
      |> Challenges.cancel_team_member_invitation()

      conn
      |> put_flash(:info, "Invitation canceled.")
      |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
    else
      conn
      |> put_flash(:error, "Action not allowed.")
      |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
    end
  end

  def kick_team_member(conn, %{
        "ngo_slug" => ngo_slug,
        "ngo_chal_slug" => slug,
        "user_id" => team_member_user_id
      }) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_flash(
          :error,
          "Invalid operation. Please make sure you are using the correct account."
        )
        |> redirect(to: page_path(conn, :login))

      logged_in_challenge_owner ->
        challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, team: [:users]])
        team_member = Challenges.get_team_member(team_member_user_id, challenge.team.id)

        case Challenges.kick_team_member(team_member, challenge, logged_in_challenge_owner) do
          {:ok, _struct} ->
            conn
            |> put_flash(:info, "Removed team member sucessfully!")
            |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))

          {:error, reason} ->
            Logger.error("Could not remove team member, reason: #{inspect(reason)}")

            conn
            |> put_flash(:error, "Could not remove team member.")
            |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
        end
    end
  end

  def add_team_member(conn, %{
        "ngo_slug" => ngo_slug,
        "ngo_chal_slug" => slug,
        "invitation_token" => invitation_token
      }) do

    case Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:team, :user, :ngo]) do
      nil ->
        conn
        |> put_flash(
          :info,
          "Challenge not found. Please make sure you clicked the correct link."
        )
        |> redirect(to: offer_path(conn, :index))

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
            |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))

          user ->
            # Make sure challenge owner cannot invite himself.
            if challenge.user.id == user.id do
              conn
              |> put_flash(
                :error,
                "You are the challenge and team leader. You cannot invite yourself."
              )
              |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
            else
              # Verify if token is related to this team.
              invitation = Challenges.get_team_member_invitation_by_token(invitation_token)

              if not is_nil(invitation) and challenge.team.id == invitation.team_id and
                   invitation.status == "pending_acceptance" do
                # Add New TeamMember to Team.
                case Challenges.add_user_to_team(%{team_id: challenge.team.id, user_id: user.id}) do
                  {:ok, _} ->
                    # Update accepted invitations counter.
                    Challenges.accepted_team_member_invitation(invitation)

                    Challenges.Notifier.send_team_owner_member_added_notification(challenge, user)

                    conn
                    |> put_flash(
                      :info,
                      "You are now part of #{inspect(User.full_name(challenge.user))} team."
                    )
                    |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))

                  {:error, reason} ->
                    Logger.info(
                      "NGOChalController: Could not add user to team, reason: #{inspect(reason)}"
                    )

                    conn
                    |> put_flash(:error, "Could not add you to team. Please contact admin@bravera.co")
                    |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
                end
              else
                # Invitation token is wrong or someone is being clever.
                conn
                |> put_flash(
                  :error,
                  "Could not add you to team. Something is wrong with your invitation link!"
                )
                |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
              end
            end
        end
    end
  end

  defp get_render_attrs(
         conn,
         %NGOChal{type: "PER_MILESTONE", has_team: false} = challenge,
         changeset,
         ngo_slug
       ) do
    %{
      challenge: challenge,
      m_targets: NGOChal.milestones_distances(challenge),
      changeset: changeset,
      stats: get_stats(challenge),
      donors: Accounts.latest_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      ngo_with_stats:
        Fundraisers.get_ngo_with_stats(ngo_slug,
          ngo_chals: [user: [:strava], team: [users: [:strava]]]
        )
    }
  end

  defp get_render_attrs(
         conn,
         %NGOChal{type: "PER_KM", has_team: false} = challenge,
         changeset,
         ngo_slug
       ) do
    %{
      challenge: challenge,
      changeset: changeset,
      donors: Accounts.latest_km_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      total_pledges_per_km: Challenges.get_per_km_challenge_total_pledges(challenge.slug),
      ngo_with_stats:
        Fundraisers.get_ngo_with_stats(ngo_slug,
          ngo_chals: [user: [:strava], team: [users: [:strava]]]
        ),
      total_one_off_donations: Challenges.get_challenge_total_one_off_donations(challenge.id),
    }
  end

  defp get_render_attrs(
         conn,
         %NGOChal{type: "PER_MILESTONE", has_team: true} = challenge,
         changeset,
         ngo_slug
       ) do
    %{
      challenge: challenge,
      m_targets: NGOChal.milestones_distances(challenge),
      changeset: changeset,
      stats: get_stats(challenge),
      donors: Accounts.latest_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      ngo_with_stats:
        Fundraisers.get_ngo_with_stats(ngo_slug,
          ngo_chals: [user: [:strava], team: [users: [:strava]]]
        ),
      all_team_members_activities_totals:
        Challenges.get_team_member_activity_totals(
          challenge.id,
          [challenge.user] ++ challenge.team.users
        )
    }
  end

  defp get_render_attrs(
         conn,
         %NGOChal{type: "PER_KM", has_team: true} = challenge,
         changeset,
         ngo_slug
       ) do
    %{
      challenge: challenge,
      changeset: changeset,
      donors: Accounts.latest_km_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      total_pledges_per_km: Challenges.get_per_km_challenge_total_pledges(challenge.slug),
      total_one_off_donations: Challenges.get_challenge_total_one_off_donations(challenge.id),
      ngo_with_stats:
        Fundraisers.get_ngo_with_stats(ngo_slug,
          ngo_chals: [user: [:strava], team: [users: [:strava]]]
        ),
      all_team_members_activities_totals:
        Challenges.get_team_member_activity_totals(
          challenge.id,
          [challenge.user] ++ challenge.team.users
        )
    }
  end

  defp create_challenge(%NGO{} = ngo, %User{} = user, attrs) do
    case attrs["has_team"] do
      "true" ->
        Challenges.create_ngo_chal_with_team(%NGOChal{}, ngo, user, attrs)

      _ ->
        Challenges.create_ngo_chal(%NGOChal{}, ngo, user, attrs)
    end
  end

  defp send_emails(%NGOChal{status: status} = challenge) do
    case status do
      "pre_registration" ->
        Challenges.Notifier.send_pre_registration_challenge_sign_up_email(challenge)

      _ ->
        Challenges.Notifier.send_challenge_signup_email(challenge)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end
end
