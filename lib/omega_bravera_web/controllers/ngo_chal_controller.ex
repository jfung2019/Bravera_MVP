defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Decimal
  alias Numbers

  alias OmegaBravera.{Accounts, Challenges, Fundraisers, Money}
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Slugify

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        # TODO slugify this ngo_id request
        %{params: %{"ngo_slug" => ngo_slug}} = conn

        ngo = Fundraisers.get_ngo_by_slug(ngo_slug)

        changeset = Challenges.change_ngo_chal(%NGOChal{})
        render(conn, "new.html", changeset: changeset, ngo: ngo)
      true ->
        redirect conn, to: "/login"
      end
  end

  def create(conn, %{"ngo_slug" => ngo_id, "ngo_chal" => chal_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    # Oddly, ngo_slug = ngo_id here...
    ngo = Fundraisers.get_ngo!(ngo_id)

    changeset_params = Map.merge(chal_params, %{"user_id" => current_user.id, "ngo_id" => ngo.id, "slug" => sluggified_username})

    case Challenges.create_ngo_chal(%NGOChal{}, changeset_params) do
      {:ok, challenge} ->
        challenge_path = ngo_ngo_chal_path(conn, :show, ngo.slug, sluggified_username)
        Challenges.send_challenge_signup_email(challenge, challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: challenge_path)
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, ngo: ngo)
    end
  end

  def show(conn, %{"slug" => slug}) do
    # TODO optimize all of the maps being passed thru into one map
    ngo_chal = Challenges.get_ngo_chal_by_slug(slug)

    %{id: ngo_chal_id, user_id: user_id, ngo_id: ngo_id, distance_target: distance_target} = ngo_chal

    user = Accounts.get_user!(user_id)
    ngo = Fundraisers.get_ngo!(ngo_id)
    strava = Accounts.get_user_strava(user_id)

    # Begin milestone donation aggregators

    charged_kickstarters = Money.get_charged_milestones(ngo_chal_id, 1)

    pending_kickstarters = Money.get_uncharged_milestones(ngo_chal_id, 1)
    pending_kicks =
      case pending_kickstarters do
        [nil] ->
          "0"
        _ ->
          [pk_decimal] = pending_kickstarters

          Decimal.to_string(pk_decimal)
      end
    charged_kicks =
      case charged_kickstarters do
        [nil] ->
          "0"
        _ ->
          [ck_decimal] = charged_kickstarters

          Decimal.to_string(ck_decimal)
      end

    kickstarters = %{"charged" => charged_kicks, "pending" => pending_kicks}

    charged_m_one = Money.get_charged_milestones(ngo_chal_id, 2)

    pending_m_one = Money.get_uncharged_milestones(ngo_chal_id, 2)

    pending_m1 =
      case pending_m_one do
        [nil] ->
          "0"
        _ ->
          [pm1_decimal] = pending_m_one
           Decimal.to_string(pm1_decimal)
      end

    charged_m1 =
      case charged_m_one do
        [nil] ->
          "0"
        _ ->
          [cm1_decimal] = charged_m_one

          Decimal.to_string(cm1_decimal)
      end

    charged_m_two = Money.get_charged_milestones(ngo_chal_id, 3)

    pending_m_two = Money.get_uncharged_milestones(ngo_chal_id, 3)

    pending_m2 =
      case pending_m_two do
        [nil] ->
          "0"
        _ ->
          [pm2_decimal] = pending_m_two

           Decimal.to_string(pm2_decimal)
      end

    charged_m2 =
      case charged_m_two do
        [nil] ->
          "0"
        _ ->
          [cm2_decimal] = charged_m_two

          Decimal.to_string(cm2_decimal)
      end

    charged_m_three = Money.get_charged_milestones(ngo_chal_id, 4)

    pending_m_three = Money.get_uncharged_milestones(ngo_chal_id, 4)

    pending_m3 =
      case pending_m_three do
        [nil] ->
          "0"
        _ ->
          [pm3_decimal] = pending_m_three

           Decimal.to_string(pm3_decimal)
      end

    charged_m3 =
      case charged_m_three do
        [nil] ->
          "0"
        _ ->
          [cm3_decimal] = charged_m_three

          Decimal.to_string(cm3_decimal)
      end

      milestone_1s = %{"charged" => charged_m1, "pending" => pending_m1, "total" => Decimal.to_string(Decimal.add(charged_m1, pending_m1))}

      milestone_2s = %{"charged" => charged_m2, "pending" => pending_m2, "total" => Decimal.to_string(Decimal.add(charged_m2, pending_m2))}

      milestone_3s = %{"charged" => charged_m3, "pending" => pending_m3, "total" => Decimal.to_string(Decimal.add(charged_m3, pending_m3))}


    milestone_targets = NGOChal.milestones_distances(ngo_chal)

    changeset = Money.change_donation(%Donation{})

    render_attrs = %{ngo_chal: ngo_chal, user: user, ngo: ngo, strava: strava, kickstarters: kickstarters, m1s: milestone_1s, m2s: milestone_2s, m3s: milestone_3s, m_targets: milestone_targets, changeset: changeset}

    render(conn, "show.html", render_attrs)
  end

  def edit(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ngo_chal" => ngo_chal_params}) do
    ngo_chal = Challenges.get_ngo_chal!(id)

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Ngo chal updated successfully.")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_chal))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
    end
  end

end
