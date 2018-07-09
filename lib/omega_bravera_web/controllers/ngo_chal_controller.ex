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

  def create(conn, %{"ngo_slug" => ngo_id_string, "ngo_chal" => ngo_chal_params}) do
    # Oddly, ngo_slug = ngo_id here...
    current_user = Guardian.Plug.current_resource(conn)

    %{id: user_id, firstname: firstname} = current_user

    ngo = Fundraisers.get_ngo!(ngo_id_string)

    %{slug: ngo_slug, id: ngo_id} = ngo

    %{"duration" => duration_str} = ngo_chal_params

    slug = Slugify.gen_random_slug(firstname)

    start_date = Timex.now

    {duration, _} = Integer.parse(duration_str)

    end_date = Timex.shift(start_date, days: duration)

    # TODO pass a map below and simplify the insert

    case Challenges.insert_ngo_chal(ngo_chal_params, ngo_id, user_id, slug, start_date, end_date) do
      {:ok, _ngo_chal} ->
        # TODO put the social share link in the put_flash?!
        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))

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

    charged_kickstarters = Money.get_charged_milestones(ngo_chal_id, 0)

    pending_kickstarters = Money.get_uncharged_milestones(ngo_chal_id, 0)
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

    charged_m_one = Money.get_charged_milestones(ngo_chal_id, 1)

    pending_m_one = Money.get_uncharged_milestones(ngo_chal_id, 1)

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

    charged_m_two = Money.get_charged_milestones(ngo_chal_id, 2)

    pending_m_two = Money.get_uncharged_milestones(ngo_chal_id, 2)

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

    charged_m_three = Money.get_charged_milestones(ngo_chal_id, 3)

    pending_m_three = Money.get_uncharged_milestones(ngo_chal_id, 3)

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

    IO.inspect(milestone_3s)


    milestone_targets = case distance_target do
        50 -> %{"1" => 0, "2" => 15, "3" => 25, "4" => 50}
        75 -> %{"1" => 0, "2" => 25, "3" => 45, "4" => 75}
        150 -> %{"1" => 0, "2" => 50, "3" => 100, "4" => 150}
        250 -> %{"1" => 0, "2" => 75, "3" => 150, "4" => 250}
      end

    changeset = Money.change_donation(%Donation{})

    render(conn, "show.html", ngo_chal: ngo_chal, user: user, ngo: ngo, strava: strava, kickstarters: kickstarters, m1s: milestone_1s, m2s: milestone_2s, m3s: milestone_3s, m_targets: milestone_targets, changeset: changeset)
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
