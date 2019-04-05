defmodule OmegaBraveraWeb.AdminPanelOfferRewardController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Offers, Repo}

  def index(conn, _params) do
    offer_rewards =
      Offers.list_offer_rewards()
      |> Repo.preload(:offer)

    render(conn, "index.html", offer_rewards: offer_rewards)
  end

  def new(conn, _params) do
    changeset = Offers.change_offer_reward(%Offers.OfferReward{})
    offers = Offers.list_offers()
    render(conn, "new.html", offers: offers, changeset: changeset)
  end

  def create(conn, %{"offer_reward" => offer_reward_params}) do
    case Offers.create_offer_reward(offer_reward_params) do
      {:ok, _sendgrid_email} ->
        conn
        |> put_flash(:info, "Reward created successfully!")
        |> redirect(to: admin_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers()
        render(conn, "new.html", offers: offers, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    offer_reward = Offers.get_offer_reward!(id)
    offers = Offers.list_offers()
    changeset = Offers.change_offer_reward(offer_reward)

    render(conn, "edit.html",
      offer_reward: offer_reward,
      offers: offers,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "offer_reward" => offer_reward_params}) do
    offer_reward = Offers.get_offer_reward!(id)

    case Offers.update_offer_reward(offer_reward, offer_reward_params) do
      {:ok, _created_sendgrid_email} ->
        conn
        |> put_flash(:info, "Reward updated successfully!")
        |> redirect(to: admin_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers()
        render(conn, "edit.html", offers: offers, changeset: changeset)
    end
  end
end