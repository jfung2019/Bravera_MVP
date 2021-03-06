defmodule OmegaBraveraWeb.OfferChallengeControllerTest do
  use OmegaBraveraWeb.ConnCase, async: false
  #  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  #
  #  import OmegaBravera.Factory
  #
  #  alias OmegaBravera.{Offers, Accounts, Repo}
  #  alias OmegaBravera.Offers.{OfferRedeem}
  #
  #  @tracker_create_attrs %{
  #    email: "user@example.com",
  #    firstname: "some firstname",
  #    lastname: "some lastname",
  #    athlete_id: 123_456,
  #    token: "132kans81h23",
  #    refresh_token: "abcd129031092asd}",
  #    token_expires_at: Timex.shift(Timex.now(), hours: 5)
  #  }
  #
  #  setup %{conn: conn} do
  #    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
  #
  #    attrs = %{
  #      firstname: "sherief",
  #      lastname: "alaa ",
  #      email: "sherief@plangora.com",
  #      email_verified: false,
  #      location_id: 1
  #    }
  #
  #    with {:ok, user} <- OmegaBravera.Accounts.create_user(attrs),
  #         {:ok, _strava} = OmegaBravera.Trackers.create_strava(user.id, @tracker_create_attrs),
  #         {:ok, token, _} <- OmegaBravera.Guardian.encode_and_sign(user, %{}),
  #         do:
  #           {:ok,
  #            conn: Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token),
  #            current_user: user}
  #  end
  #
  #  describe "create" do
  #    @tag :skip
  #    test "create/2 refuses to create challenge if offer end date was reached", %{
  #      conn: conn,
  #      current_user: user
  #    } do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{start_date: Timex.now(), end_date: Timex.shift(Timex.now(), days: -5)})
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_path(conn, :create, offer.slug)
  #        )
  #
  #      assert get_session(conn, :could_not_create_offer_challenge) == true
  #      assert Offers.list_offer_challenges() == []
  #    end
  #
  #    @tag :skip
  #    test "create/2 creates a pre_registration challenge within time limit of an offer", %{
  #      conn: conn,
  #      current_user: user
  #    } do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{
  #          open_registration: false,
  #          pre_registration_start_date: Timex.now(),
  #          start_date: Timex.shift(Timex.now(), days: 5),
  #          end_date: Timex.shift(Timex.now(), days: 10),
  #          time_limit: 5
  #        })
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_path(conn, :create, offer.slug)
  #        )
  #
  #      assert %{slug: slug} = redirected_params(conn)
  #
  #      created_challenge = Offers.get_offer_chal_by_slugs(offer.slug, slug)
  #
  #      assert Timex.equal?(created_challenge.start_date, offer.start_date)
  #      assert Timex.equal?(created_challenge.end_date, offer.end_date)
  #
  #      assert get_session(conn, "created_offer_challenge") == true
  #    end
  #
  #    @tag :skip
  #    test "create/2 creates a pre_registration challenge", %{
  #      conn: conn,
  #      current_user: user
  #    } do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{
  #          open_registration: false,
  #          pre_registration_start_date: Timex.now(),
  #          start_date: Timex.shift(Timex.now(), days: 5),
  #          end_date: Timex.shift(Timex.now(), days: 10),
  #          time_limit: 0
  #        })
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_path(conn, :create, offer.slug)
  #        )
  #
  #      assert %{slug: slug} = redirected_params(conn)
  #
  #      created_challenge = Offers.get_offer_chal_by_slugs(offer.slug, slug)
  #
  #      assert created_challenge.status == "pre_registration"
  #      assert Timex.equal?(created_challenge.start_date, offer.start_date)
  #      assert Timex.equal?(created_challenge.end_date, offer.end_date)
  #    end
  #
  #    @tag :skip
  #    test "create/2 redirects to challenge when data is valid", %{conn: conn, current_user: user} do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{start_date: Timex.now(), end_date: Timex.shift(Timex.now(), days: 10)})
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_path(conn, :create, offer.slug)
  #        )
  #
  #      assert get_flash(conn, :info) == "Success! You have registered for this offer!"
  #      assert [challenge] = Offers.list_offer_challenges()
  #
  #      assert redirected_to(conn) ==
  #               Routes.offer_offer_challenge_path(conn, :show, offer, challenge)
  #    end
  #
  #    @tag :skip
  #    test "create/2 redirects to paid offer challenge when data is valid", %{
  #      conn: conn,
  #      current_user: user
  #    } do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{
  #          start_date: Timex.now(),
  #          end_date: Timex.shift(Timex.now(), days: 10),
  #          payment_amount: Decimal.new(57)
  #        })
  #
  #      use_cassette "signup_for_paid_offer" do
  #        conn =
  #          post(
  #            conn,
  #            Routes.offer_offer_challenge_path(conn, :create, offer.slug),
  #            offer_challenge: %{
  #              "team" => %{},
  #              "offer_redeems" => [%{}],
  #              "payment" => %{"stripe_token" => "tok_1ElwBZEXtHU8QBy8ZPONLVaF"}
  #            }
  #          )
  #
  #        assert get_flash(conn, :info) == "Success! You have registered for this offer!"
  #        assert [challenge] = Offers.list_offer_challenges()
  #
  #        assert redirected_to(conn) ==
  #                 Routes.offer_offer_challenge_path(conn, :show, offer, challenge)
  #
  #        challenge = Repo.preload(challenge, :payment)
  #        assert Decimal.round(challenge.payment.charged_amount) == offer.payment_amount
  #        assert challenge.payment.status == "charged"
  #      end
  #    end
  #
  #    @tag :skip
  #    test "create/2 redirects to paid offer challenge of type BRAVERA_SEGMENT when data is valid",
  #         %{
  #           conn: conn,
  #           current_user: user
  #         } do
  #      {:ok, _user} =
  #        Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer =
  #        insert(:offer, %{
  #          start_date: Timex.now(),
  #          end_date: Timex.shift(Timex.now(), days: 10),
  #          payment_amount: Decimal.new(57),
  #          offer_challenge_types: ["BRAVERA_SEGMENT"]
  #        })
  #
  #      use_cassette "signup_for_paid_offer" do
  #        conn =
  #          post(
  #            conn,
  #            Routes.offer_offer_challenge_path(conn, :create, offer.slug),
  #            offer_challenge: %{
  #              "team" => %{},
  #              "offer_redeems" => [%{}],
  #              "payment" => %{"stripe_token" => "tok_1ElwBZEXtHU8QBy8ZPONLVaF"}
  #            }
  #          )
  #
  #        assert get_flash(conn, :info) == "Success! You have registered for this offer!"
  #        assert [challenge] = Offers.list_offer_challenges()
  #
  #        assert redirected_to(conn) ==
  #                 Routes.offer_offer_challenge_path(conn, :show, offer, challenge)
  #
  #        challenge = Repo.preload(challenge, :payment)
  #        assert Decimal.round(challenge.payment.charged_amount) == offer.payment_amount
  #        assert challenge.payment.status == "charged"
  #        assert challenge.type == hd(offer.offer_challenge_types)
  #      end
  #    end
  #  end
  #
  #  @tag :skip
  #  test "unverified user should get their session saved with where to go when they verify email",
  #       %{conn: conn, current_user: _user} do
  #    offer = insert(:offer, %{slug: "sherief-1"})
  #
  #    conn = get(conn, Routes.offer_offer_challenge_path(conn, :new, offer))
  #    assert html_response(conn, 200) =~ "verify your email address"
  #
  #    after_email_verify =
  #      Plug.Conn.fetch_cookies(conn)
  #      |> Map.get(:cookies)
  #      |> Map.get("after_email_verify")
  #
  #    assert after_email_verify == Routes.offer_offer_challenge_path(conn, :new, offer)
  #  end
  #
  #  @tag :skip
  #  test "when a user changes their email, email_verified will be set to false and email_activation_token will change too",
  #       %{conn: conn, current_user: user} do
  #    offer = insert(:offer, %{slug: "sherief-1"})
  #
  #    {:ok, updated_user} =
  #      Accounts.update_user(user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #    post(conn, user_path(conn, :update, %{"user" => %{email: "sherief@gmail.com"}}))
  #    updated_user2 = Accounts.get_user!(updated_user.id)
  #
  #    assert updated_user2.email == "sherief@gmail.com"
  #    assert updated_user2.email_activation_token != updated_user.email_activation_token
  #    refute updated_user2.email_verified
  #
  #    conn = get(conn, Routes.offer_offer_challenge_path(conn, :new, offer))
  #
  #    after_email_verify =
  #      Plug.Conn.fetch_cookies(conn)
  #      |> Map.get(:cookies)
  #      |> Map.get("after_email_verify")
  #
  #    assert after_email_verify == Routes.offer_offer_challenge_path(conn, :new, offer)
  #  end
  #
  #  @tag :skip
  #  test "created challenge should first show a success modal", %{conn: conn, current_user: user} do
  #    offer = insert(:offer, %{slug: "sherief-1"})
  #    challenge = insert(:offer_challenge, %{offer: offer, user: user})
  #
  #    conn =
  #      conn
  #      |> bypass_through(OmegaBraveraWeb.Router, :browser)
  #      |> get("/")
  #      |> put_session("created_offer_challenge", true)
  #      |> send_resp(:ok, "")
  #      |> get(offer_offer_challenge_path(conn, :show, offer, challenge))
  #
  #    assert %{assigns: %{created_offer_challenge: true}} = conn
  #    assert get_session(conn, "created_offer_challenge") == nil
  #  end
  #
  #  describe "redeem" do
  #    test "new_redeem/2 renders redeem form for vendor", %{conn: conn} do
  #      offer_redeem = insert(:offer_redeem)
  #
  #      conn =
  #        get(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :new_redeem,
  #            offer_redeem.offer.slug,
  #            offer_redeem.offer_challenge.slug,
  #            offer_redeem.token
  #          )
  #        )
  #
  #      assert html_response(conn, 200) =~ "New Redemption"
  #    end
  #
  #    test "new_redeem/2 will not show form for vendor as it is expired", %{conn: conn} do
  #      offer_redeem = insert(:offer_redeem, status: "expired")
  #
  #      conn =
  #        get(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :new_redeem,
  #            offer_redeem.offer.slug,
  #            offer_redeem.offer_challenge.slug,
  #            offer_redeem.token
  #          )
  #        )
  #
  #      assert html_response(conn, 200) =~ "Redemption Expired"
  #    end
  #
  #    test "save_redeem/2 updates a redeem when valid data is given", %{conn: conn} do
  #      offer_redeem = insert(:offer_redeem)
  #
  #      params = %{
  #        vendor_id: offer_redeem.vendor.vendor_id,
  #        offer_reward_id: offer_redeem.offer_reward.id
  #      }
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :save_redeem,
  #            offer_redeem.offer.slug,
  #            offer_redeem.offer_challenge.slug,
  #            offer_redeem.token
  #          ),
  #          offer_redeem: params
  #        )
  #
  #      assert html = html_response(conn, 200)
  #      assert html =~ "Confirmed!"
  #      assert html =~ "Total Redemptions to date:</span>\n        <span><b>1"
  #
  #      offer_redeemed_ = Offers.get_offer_redeems!(offer_redeem.id)
  #      assert offer_redeemed_.status == "redeemed"
  #    end
  #
  #    test "save_redeem/2 will not update a redeem when valid data is given but redeem is expired",
  #         %{conn: conn} do
  #      offer_redeem = insert(:offer_redeem, %{status: "expired"})
  #
  #      params = %{
  #        vendor_id: offer_redeem.vendor.vendor_id,
  #        offer_reward_id: offer_redeem.offer_reward.id
  #      }
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :save_redeem,
  #            offer_redeem.offer.slug,
  #            offer_redeem.offer_challenge.slug,
  #            offer_redeem.token
  #          ),
  #          offer_redeem: params
  #        )
  #
  #      assert html = html_response(conn, 200)
  #      assert html =~ "Redemption Expired"
  #
  #      offer_redeemed_ = Offers.get_offer_redeems!(offer_redeem.id)
  #      assert offer_redeemed_.status == "expired"
  #    end
  #
  #    test "save_redeem/2 renders errors when invalid data is given", %{conn: conn} do
  #      offer_redeem = insert(:offer_redeem)
  #
  #      params = %{vendor_id: "", offer_reward_id: offer_redeem.offer_reward.id}
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :save_redeem,
  #            offer_redeem.offer.slug,
  #            offer_redeem.offer_challenge.slug,
  #            offer_redeem.token
  #          ),
  #          offer_redeem: params
  #        )
  #
  #      assert html_response(conn, 200) =~ "Vendor not found in database."
  #
  #      offer = Offers.get_offer_by_slug(offer_redeem.offer.slug, [:offer_redeems])
  #      assert length(offer.offer_redeems) == 1
  #      offer_redeemed_ = Offers.get_offer_redeems!(offer_redeem.id)
  #      assert offer_redeemed_.status == "pending"
  #    end
  #  end
  #
  #  describe "accept team invites" do
  #    test "add_team_member/2 adds user to a team", %{conn: conn, current_user: current_user} do
  #      {:ok, updated_user} =
  #        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      team = insert(:offer_challenge_team)
  #
  #      invitation =
  #        insert(:offer_team_invitation, %{email: updated_user.email, team_id: team.id, team: nil})
  #
  #      conn =
  #        get(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :add_team_member,
  #            team.offer_challenge.offer.slug,
  #            team.offer_challenge.slug,
  #            invitation.token
  #          )
  #        )
  #
  #      assert get_flash(conn, :info) =~
  #               "You are now part of #{inspect(Accounts.User.full_name(team.user))} team."
  #
  #      updated_team =
  #        Offers.get_team!(team.id)
  #        |> Repo.preload(:invitations)
  #        |> Repo.preload(:users)
  #
  #      assert length(updated_team.invitations) == 1
  #      assert %{status: "accepted"} = hd(updated_team.invitations)
  #      assert invitation.email == hd(updated_team.users).email
  #
  #      team_user_redeem =
  #        Repo.get_by(OfferRedeem,
  #          offer_challenge_id: team.offer_challenge_id,
  #          user_id: hd(updated_team.users).id
  #        )
  #
  #      assert team_user_redeem.user_id != team.user_id
  #      assert updated_user.email == hd(updated_team.users).email
  #    end
  #
  #    # TODO: Fix lib/omega_bravera_web/controllers/offer/offer_challenge_controller.ex:233
  #
  #    # test "add_team_member/2 does not invite user if token is invalid", %{conn: conn, current_user: current_user} do
  #    #   {:ok, updated_user} =
  #    #     Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #    #   team = insert(:offer_challenge_team)
  #    #   insert(:offer_team_invitation, %{email: updated_user.email, team_id: team.id, team: nil})
  #
  #    #   bad_token = "non-existent-token"
  #
  #    #   conn =
  #    #     get(
  #    #       conn,
  #    #       Routes.offer_offer_challenge_offer_challenge_path(
  #    #         conn,
  #    #         :add_team_member,
  #    #         team.offer_challenge.offer.slug,
  #    #         team.offer_challenge.slug,
  #    #         bad_token
  #    #       )
  #    #     )
  #
  #    #   assert get_flash(conn, :error) =~
  #    #            "Could not add you to team. Something is wrong with your invitation link!"
  #
  #    #   updated_team =
  #    #     Offers.get_team!(team.id)
  #    #     |> Repo.preload(:invitations)
  #
  #    #   assert length(updated_team.invitations) == 1
  #    #   assert %{status: "pending_acceptance"} = hd(updated_team.invitations)
  #    # end
  #  end
  #
  #  describe "kick team member" do
  #    test "kick_team_member/3 can kick team member out of offer challenge team", %{
  #      conn: conn,
  #      current_user: current_user
  #    } do
  #      {:ok, updated_user} =
  #        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer_challenge =
  #        insert(:offer_challenge, %{has_team: true, user: nil, user_id: updated_user.id})
  #
  #      team = insert(:offer_challenge_team, %{offer_challenge: offer_challenge})
  #      team_member_user = insert(:user)
  #
  #      insert(:offer_team_invitation, %{
  #        team: nil,
  #        team_id: team.id,
  #        email: team_member_user.email,
  #        status: "accepted"
  #      })
  #
  #      insert(:offer_challenge_team_member, %{team_id: team.id, user_id: team_member_user.id})
  #      updated_team = Repo.get_by(Offers.OfferChallengeTeam, id: team.id) |> Repo.preload(:users)
  #
  #      assert length(updated_team.users) == 1
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :kick_team_member,
  #            offer_challenge.offer.slug,
  #            offer_challenge.slug,
  #            team_member_user.id
  #          )
  #        )
  #
  #      assert get_flash(conn, :info) =~ "Removed team member sucessfully!"
  #    end
  #
  #    test "kick_team_member/3 only the logged in a challenge owner can kick team member", %{
  #      conn: conn,
  #      current_user: current_user
  #    } do
  #      {:ok, _updated_user} =
  #        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      not_challenge_owner_user = insert(:user)
  #
  #      offer_challenge =
  #        insert(:offer_challenge, %{
  #          has_team: true,
  #          user: nil,
  #          user_id: not_challenge_owner_user.id
  #        })
  #
  #      team = insert(:offer_challenge_team, %{offer_challenge: offer_challenge})
  #      team_member_user = insert(:user)
  #      insert(:offer_challenge_team_member, %{team_id: team.id, user_id: team_member_user.id})
  #      updated_team = Repo.get_by(Offers.OfferChallengeTeam, id: team.id) |> Repo.preload(:users)
  #
  #      assert length(updated_team.users) == 1
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :kick_team_member,
  #            offer_challenge.offer.slug,
  #            offer_challenge.slug,
  #            team_member_user.id
  #          )
  #        )
  #
  #      assert get_flash(conn, :error) =~ "Could not remove team member."
  #    end
  #
  #    test "kick_team_member/3 cannot kick member after challenge is complete", %{
  #      conn: conn,
  #      current_user: current_user
  #    } do
  #      {:ok, updated_user} =
  #        Accounts.update_user(current_user, %{email: "sherief@plangora.com", email_verified: true})
  #
  #      offer_challenge =
  #        insert(:offer_challenge, %{
  #          has_team: true,
  #          user: nil,
  #          user_id: updated_user.id,
  #          status: "complete"
  #        })
  #
  #      team = insert(:offer_challenge_team, %{offer_challenge: offer_challenge})
  #      team_member_user = insert(:user)
  #      insert(:offer_challenge_team_member, %{team_id: team.id, user_id: team_member_user.id})
  #      updated_team = Repo.get_by(Offers.OfferChallengeTeam, id: team.id) |> Repo.preload(:users)
  #
  #      assert length(updated_team.users) == 1
  #
  #      conn =
  #        post(
  #          conn,
  #          Routes.offer_offer_challenge_offer_challenge_path(
  #            conn,
  #            :kick_team_member,
  #            offer_challenge.offer.slug,
  #            offer_challenge.slug,
  #            team_member_user.id
  #          )
  #        )
  #
  #      assert get_flash(conn, :error) =~ "Could not remove team member."
  #    end
  #  end
end
