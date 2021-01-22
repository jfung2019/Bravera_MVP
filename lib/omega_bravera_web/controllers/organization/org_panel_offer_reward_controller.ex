defmodule OmegaBraveraWeb.OrgPanelOfferRewardController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Offers

  def index(%{assigns: %{organization_id: org_id}} = conn, params) do
    results = Offers.paginate_offer_rewards(org_id, params)
    new_reward = Offers.new_reward_created(org_id)

    render(conn, "index.html",
      offer_rewards: results.offer_rewards,
      paginate: results.paginate,
      new_reward: new_reward
    )
  end

  def new(%{assigns: %{organization_id: org_id}} = conn, _params) do
    changeset = Offers.change_offer_reward(%Offers.OfferReward{})
    offers = Offers.list_offers_by_organization(org_id)
    render(conn, "new.html", offers: offers, changeset: changeset)
  end

  def create(%{assigns: %{organization_id: org_id}} = conn, %{
        "offer_reward" => offer_reward_params
      }) do
    case Offers.create_offer_reward(offer_reward_params) do
      {:ok, _sendgrid_email} ->
        conn
        |> put_flash(:info, "Reward created successfully!")
        |> redirect(to: Routes.org_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers_by_organization(org_id)
        render(conn, "new.html", offers: offers, changeset: changeset)
    end
  end

  def edit(%{assigns: %{organization_id: org_id}} = conn, %{"id" => id}) do
    offer_reward = Offers.get_offer_reward!(id)
    offers = Offers.list_offers_by_organization(org_id)
    changeset = Offers.change_offer_reward(offer_reward)

    render(conn, "edit.html",
      offer_reward: offer_reward,
      offers: offers,
      changeset: changeset
    )
  end

  def update(%{assigns: %{organization_id: org_id}} = conn, %{
        "id" => id,
        "offer_reward" => offer_reward_params
      }) do
    offer_reward = Offers.get_offer_reward!(id)

    case Offers.update_offer_reward(offer_reward, offer_reward_params) do
      {:ok, _created_sendgrid_email} ->
        conn
        |> put_flash(:info, "Reward updated successfully!")
        |> redirect(to: Routes.org_panel_offer_reward_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        offers = Offers.list_offers_by_organization(org_id)
        render(conn, "edit.html", offers: offers, changeset: changeset)
    end
  end
end
