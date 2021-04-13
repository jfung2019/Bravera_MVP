defmodule OmegaBraveraWeb.Api.Resolvers.OfferChallenges do
  require Logger
  import OmegaBraveraWeb.Gettext

  alias OmegaBravera.{Accounts, Offers, Repo}
  alias OmegaBraveraWeb.Offer.OfferChallengeHelper
  alias OmegaBraveraWeb.Api.Resolvers.Helpers

  def create_segment_challenge(_root, %{offer_slug: offer_slug, stripe_token: stripe_token}, %{
        context: %{current_user: %{id: _} = current_user}
      }) do
    offer = Offers.get_offer_by_slug(offer_slug)

    case Offers.create_offer_challenge(offer, current_user, %{
           "payment" => %{"stripe_token" => stripe_token},
           "team" => %{},
           "offer_redeems" => [%{}]
         }) do
      {:ok, offer_challenge} ->
        OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))

        {:ok, %{offer_challenge: offer_challenge}}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.info(
          "API: Could not sign up user for segment offer. Reason: #{inspect(changeset)}"
        )

        {:error,
         message: gettext("Could not create segment challenge."),
         details: Helpers.transform_errors(changeset)}
    end
  end

  def buy(_root, %{offer_slug: offer_slug}, %{context: %{current_user: %{id: user_id}}}) do
    user = Accounts.get_user_with_points(user_id)

    with %{} = offer <- Offers.get_allowed_offer_by_slug_and_user_id(offer_slug, user_id),
         {:ok, %{create_offer_challenge_with_points: offer_challenge}} <-
           Offers.buy_offer_with_points(offer, user) do
      offer_redeem =
        Repo.get_by(OmegaBravera.Offers.OfferRedeem,
          user_id: user.id,
          offer_challenge_id: offer_challenge.id
        )

      OmegaBravera.Offers.Notifier.send_points_reward_email(offer_challenge, user, offer_redeem)

      {:ok, %{offer_challenge: offer_challenge, user_profile: Accounts.api_user_profile(user_id)}}
    else
      :not_authorized ->
        {:error, message: gettext("Please join partner to join challenge")}

      :no_active_device ->
        {:error, message: gettext("Please connect Google Fit / Apple Health to bravera")}

      {:error, :create_offer_challenge_with_points, changeset, _changes} ->
        Logger.info("Could buy offer, reason: #{inspect(changeset)}")

        {:error,
         message: gettext("Could not buy offer challenge with user points."),
         details: Helpers.transform_errors(changeset)}
    end
  end

  def earn(_root, %{offer_slug: offer_slug} = args, %{
        context: %{current_user: current_user}
      }) do
    current_user = Accounts.get_user_with_active_challenges(current_user.id)

    attrs =
      if stripe_token = Map.get(args, :stripe_token),
        do: %{
          "payment" => %{"stripe_token" => stripe_token},
          "team" => %{},
          "offer_redeems" => [%{}]
        },
        else: %{team: %{}, offer_redeems: [%{}], payment: %{}}

    with %{} = offer <- Offers.get_allowed_offer_by_slug_and_user_id(offer_slug, current_user.id),
         {:ok, offer_challenge} <- Offers.create_offer_challenge(offer, current_user, attrs) do
      OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))
      # TODO: Find a way to make this a trigger
      Absinthe.Subscription.publish(
        OmegaBraveraWeb.Endpoint,
        OmegaBravera.Accounts.user_live_challenges(current_user.id),
        live_challenges: current_user.id
      )

      {:ok, %{offer_challenge: offer_challenge}}
    else
      :not_authorized ->
        {:error, message: gettext("Please join partner to join challenge")}

      :no_active_device ->
        {:error, message: gettext("Please connect Google Fit / Apple Health to bravera")}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.info("API: Could not sign up user for offer. Reason: #{inspect(changeset)}")

        {:error,
         message: gettext("Could not create offer challenge."),
         details: Helpers.transform_errors(changeset)}
    end
  end

  def create(_root, %{input: %{offer_slug: offer_slug}}, %{context: %{current_user: current_user}}) do
    case Offers.get_offer_by_slug(offer_slug) do
      nil ->
        {:error, "Offer not found"}

      offer ->
        create_challenge(offer, current_user)
    end
  end

  def create(_, _, %{}),
    do: {:error, "Action Requires Login"}

  defp create_challenge(offer, current_user) do
    # Load user offer challenges.
    current_user = Accounts.get_user_with_active_challenges(current_user.id)

    case Offers.create_offer_challenge(offer, current_user) do
      {:ok, offer_challenge} ->
        OfferChallengeHelper.send_emails(Repo.preload(offer_challenge, :user))
        {:ok, %{offer_challenge: offer_challenge}}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("API: Could not sign up user for offer. Reason: #{inspect(changeset)}")

        {:error,
         message: "Could not create offer challenge", details: Helpers.transform_errors(changeset)}
    end
  end

  def get_challenge_redeem(_root, %{challenge_id: challenge_id}, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Offers.get_redeem(challenge_id, user_id) do
      nil ->
        {:error,
         message: "Redeem not found.",
         details: "Could not find redeem using provided challenge_id and user_id."}

      redeem ->
        {:ok, redeem}
    end
  end
end
