defmodule OmegaBraveraWeb.NGOChalControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Trackers, Challenges, Accounts.User, Repo}

  @create_attrs %{
    "activity_type" => "Walk",
    "distance_target" => "100",
    "duration" => "20",
    "has_team" => "false",
    "money_target" => "500",
    "type" => "PER_MILESTONE",
    "team" => %{"name" => "", "count" => ""}
  }
  @tracker_create_attrs %{
    email: "user@example.com",
    firstname: "some firstname",
    lastname: "some lastname",
    athlete_id: 123_456,
    token: "132kans81h23",
    refresh_token: "abcd129031092asd}",
    token_expires_at: Timex.shift(Timex.now(), hours: 5)
  }
  @invalid_attrs %{
    "activity_type" => "",
    "distance_target" => "",
    "duration" => "",
    "has_team" => "",
    "money_target" => "",
    "type" => "",
    "team" => %{"name" => "", "count" => ""}
  }

  setup %{conn: conn} do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa ",
      email: "user@example.com",
      email_verified: true,
      location_id: 1
    }

    with {:ok, user} <- Accounts.create_user(attrs),
         {:ok, _strava} = Trackers.create_strava(user.id, @tracker_create_attrs),
         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
         do:
           {:ok,
            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
            current_user: user}
  end

  @tag :authenticated
  test "new ngo_chal renders form", %{conn: conn} do
    ngo = insert(:ngo, %{url: "http://localhost:4000"})
    conn = get(conn, ngo_ngo_chal_path(conn, :new, ngo.slug))

    assert html_response(conn, 200) =~ "localhost"
  end

  test "new ngo_chal renders 404 if missing ngo", %{conn: conn} do
    conn = get(conn, ngo_ngo_chal_path(conn, :new, "invalid-ngo"))

    assert html_response(conn, 404) =~ "You look lost, Mate."
  end

  describe "create ngo_chal" do
    test "redirects to show when data is valid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000"})
      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: @create_attrs)

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo.slug, slug)

      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo.slug, slug))
      assert html_response(conn, 200) =~ ngo.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000"})
      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: @invalid_attrs)
      assert html_response(conn, 200) =~ ngo.name
    end

    test "redirects to show when team data is valid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000", additional_members: 5})

      create_attrs_with_team =
        @create_attrs
        |> Map.put("has_team", "true")
        |> put_in(["team", "name"], "Sherief's team 7")
        |> put_in(["team", "count"], ngo.additional_members)

      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: create_attrs_with_team)

      assert %{slug: slug} = redirected_params(conn)
      assert redirected_to(conn) == ngo_ngo_chal_path(conn, :show, ngo.slug, slug)

      ngo_chal_with_team = Challenges.get_ngo_chal_by_slugs(ngo.slug, slug, [:team])
      assert ngo_chal_with_team.team.name == create_attrs_with_team["team"]["name"]
      assert ngo_chal_with_team.team.count == ngo.additional_members - 1
    end

    test "renders errors when tea, data is invalid", %{conn: conn} do
      ngo = insert(:ngo, %{url: "http://localhost:4000", additional_members: 5})

      create_attrs_with_team =
        @create_attrs
        |> Map.put("has_team", "true")
        |> put_in(["team", "name"], "")
        |> put_in(["team", "count"], ngo.additional_members)

      conn = post(conn, ngo_ngo_chal_path(conn, :create, ngo), ngo_chal: create_attrs_with_team)
      assert html_response(conn, 200) =~ ngo.name
    end
  end

  describe "show ngo_chal" do
    setup do
      ngo_1 = insert(:ngo, %{slug: "ngo-1"})
      ngo_2 = insert(:ngo, %{slug: "ngo-2"})
      strava = insert(:strava)

      challenge_1 =
        insert(:ngo_challenge, %{
          ngo: ngo_1,
          default_currency: "hkd",
          user: strava.user
        })

      challenge_2 =
        insert(:ngo_challenge, %{
          ngo: ngo_2,
          default_currency: "myr",
          user: strava.user
        })

      {:ok, %{ngo_1: ngo_1, ngo_2: ngo_2, challenge_1: challenge_1, challenge_2: challenge_2}}
    end

    test "challenge 1 renders properly", %{conn: conn, challenge_1: challenge, ngo_1: ngo} do
      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo, challenge))

      assert html_response(conn, 200) =~ "HK$"
    end

    test "challenge 2 renders properly", %{conn: conn, challenge_2: challenge, ngo_2: ngo} do
      conn = get(conn, ngo_ngo_chal_path(conn, :show, ngo, challenge))

      assert html_response(conn, 200) =~ "RM"
    end

    test "invalid slug for NGO and challenge will render 404", %{conn: conn} do
      conn = get(conn, "/invalid-ngo/invalid-challenge")

      assert html_response(conn, 404) =~ "You look lost, Mate."
    end

    test "invalid slug for NGO, valid challenge will render 404", %{conn: conn, challenge_1: chal} do
      conn = get(conn, "/invalid-ngo/i#{chal.slug}")

      assert html_response(conn, 404) =~ "You look lost, Mate."
    end

    test "valid slug for NGO, valid challenge will render 404", %{conn: conn, ngo_1: ngo} do
      conn = get(conn, "/#{ngo.slug}/invalid-challenge")

      assert html_response(conn, 404) =~ "You look lost, Mate."
    end

    test "add_team_member/2 adds user to a team", %{conn: conn, current_user: current_user} do
      team = insert(:team)

      invitation =
        insert(:team_invitation, %{email: current_user.email, team_id: team.id, team: nil})

      conn =
        get(
          conn,
          ngo_ngo_chal_ngo_chal_path(
            conn,
            :add_team_member,
            team.challenge.ngo.slug,
            team.challenge.slug,
            invitation.token
          )
        )

      assert get_flash(conn, :info) =~
               "You are now part of #{inspect(User.full_name(team.user))} team."

      updated_team =
        Challenges.get_team!(team.id)
        |> Repo.preload(:invitations)
        |> Repo.preload(:users)

      assert length(updated_team.invitations) == 1
      assert %{status: "accepted"} = hd(updated_team.invitations)
      assert invitation.email == hd(updated_team.users).email
    end

    test "add_team_member/2 does not invite user if token is invalid", %{conn: conn} do
      team = insert(:team)
      insert(:team_invitation, %{team_id: team.id, team: nil})
      bad_token = "non-existent-token"

      conn =
        get(
          conn,
          ngo_ngo_chal_ngo_chal_path(
            conn,
            :add_team_member,
            team.challenge.ngo.slug,
            team.challenge.slug,
            bad_token
          )
        )

      assert get_flash(conn, :error) =~
               "Could not add you to team. Something is wrong with your invitation link!"

      updated_team =
        Challenges.get_team!(team.id)
        |> Repo.preload(:invitations)

      assert length(updated_team.invitations) == 1
      assert %{status: "pending_acceptance"} = hd(updated_team.invitations)
    end
  end

  describe "kick team member" do
    test "kick_team_member/3 can kick team member out of ngo challenge team", %{
      conn: conn,
      current_user: current_user
    } do
      {:ok, updated_user} =
        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})

      challenge =
        insert(:ngo_challenge, %{has_team: true, user: nil, user_id: updated_user.id})

      team = insert(:team, %{challenge: challenge})
      team_member_user = insert(:user)
      insert(:team_member, %{team_id: team.id, user_id: team_member_user.id})
      insert(:team_invitation, %{team: nil, team_id: team.id, email: team_member_user.email, status: "accepted"})
      updated_team = Repo.get_by(Challenges.Team, id: team.id) |> Repo.preload(:users)

      assert length(updated_team.users) == 1

      conn =
        post(
          conn,
          ngo_ngo_chal_ngo_chal_path(
            conn,
            :kick_team_member,
            challenge.ngo.slug,
            challenge.slug,
            team_member_user.id
          )
        )

      assert get_flash(conn, :info) =~ "Removed team member sucessfully!"
    end

    test "kick_team_member/3 only the logged in a challenge owner can kick team member", %{
      conn: conn,
      current_user: current_user
    } do
      {:ok, _updated_user} =
        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})

      not_challenge_owner_user = insert(:user)

      challenge =
        insert(:ngo_challenge, %{has_team: true, user: nil, user_id: not_challenge_owner_user.id})

      team = insert(:team, %{challenge: challenge})
      team_member_user = insert(:user)
      insert(:team_invitation, %{team: nil, team_id: team.id, email: team_member_user.email, status: "accepted"})
      insert(:team_member, %{team_id: team.id, user_id: team_member_user.id})
      updated_team = Repo.get_by(Challenges.Team, id: team.id) |> Repo.preload(:users)

      assert length(updated_team.users) == 1

      conn =
        post(
          conn,
          ngo_ngo_chal_ngo_chal_path(
            conn,
            :kick_team_member,
            challenge.ngo.slug,
            challenge.slug,
            team_member_user.id
          )
        )

      assert get_flash(conn, :error) =~ "Could not remove team member."
    end

    test "kick_team_member/3 cannot kick member after challenge is complete", %{
      conn: conn,
      current_user: current_user
    } do
      {:ok, updated_user} =
        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})

      challenge =
        insert(:ngo_challenge, %{has_team: true, user: nil, user_id: updated_user.id, status: "complete"})

      team = insert(:team, %{challenge: challenge})
      team_member_user = insert(:user)
      insert(:team_member, %{team_id: team.id, user_id: team_member_user.id})
      updated_team = Repo.get_by(Challenges.Team, id: team.id) |> Repo.preload(:users)

      assert length(updated_team.users) == 1

      conn =
        post(
          conn,
          ngo_ngo_chal_ngo_chal_path(
            conn,
            :kick_team_member,
            challenge.ngo.slug,
            challenge.slug,
            team_member_user.id
          )
        )

      assert get_flash(conn, :error) =~ "Could not remove team member."
    end
  end
end
