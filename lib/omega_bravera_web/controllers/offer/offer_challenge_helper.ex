defmodule OmegaBraveraWeb.Offer.OfferChallengeHelper do
  alias OmegaBravera.Offers.OfferChallenge
  alias OmegaBravera.Offers

  def send_emails(%OfferChallenge{status: status, has_team: false} = challenge) do
    case status do
      "pre_registration" ->
        Offers.Notifier.send_pre_registration_challenge_sign_up_email(challenge)

      _ ->
        Offers.Notifier.send_challenge_signup_email(challenge, challenge.user)
    end
  end

  def send_emails(%OfferChallenge{status: status, has_team: true} = challenge) do
    case status do
      "pre_registration" ->
        Offers.Notifier.send_pre_registration_challenge_sign_up_email(challenge)

      _ ->
        Offers.Notifier.send_team_challenge_signup_email(challenge, challenge.user)
    end
  end
end
