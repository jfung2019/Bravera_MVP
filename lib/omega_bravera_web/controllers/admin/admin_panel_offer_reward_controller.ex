defmodule OmegaBraveraWeb.AdminPanelOfferRewardController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Offers

  def index(conn, params) do
    results = check_view_as(conn, params)
    render(conn, "index.html", offer_rewards: results.offer_rewards, paginate: results.paginate)
  end

  defp check_view_as(%{assigns: %{view_as_org: %{id: org_id}}}, params),
    do: Offers.paginate_offer_rewards(org_id, params)

  defp check_view_as(conn, params),
    do: Offers.paginate_offer_rewards(Guardian.Plug.current_resource(conn), params)

  def new(conn, _params) do
    changeset = Offers.change_offer_reward(%Offers.OfferReward{})
    offers = Offers.list_offers_all_offers()
    render(conn, "new.html", offers: offers, changeset: changeset)
  end

  def create(conn, %{"offer_reward" => offer_reward_params}) do
    case Offers.create_offer_reward(offer_reward_params) do
      {:ok, _sendgrid_email} ->
        conn
        |> put_flash(:info, "Reward created successfully!")
        |> redirect(to: Routes.admin_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers_all_offers()
        render(conn, "new.html", offers: offers, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    offer_reward = Offers.get_offer_reward!(id)
    offers = Offers.list_offers_all_offers()
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
        |> redirect(to: Routes.admin_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers_all_offers()
        render(conn, "edit.html", offers: offers, changeset: changeset)
    end
  end
end
