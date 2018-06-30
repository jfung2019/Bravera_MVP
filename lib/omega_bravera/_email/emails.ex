defmodule OmegaBravera.Emails do
  import Bamboo.Email

  def welcome_email(recipient) do
    new_email()
    |> to(recipient)
    |> from("no-reply@bravera.co")
    |> subject("Welcome!")
    |> html_body("<strong>Thanks for joining!</strong>")
    |> text_body("Thanks for joining!")
  end

  def participant_registration(recipient, challenge_params) do
    %{"challenge" => challenge, "challenge_slug" => challenge_slug, "participant_slug" => participant_slug} = challenge_params

    new_email()
    |> to(recipient)
    |> from("no-reply@bravera.co")
    |> subject("#{challenge} Registration Complete")
    |> html_body("You have successfully registered for #{challenge}. Share this link with your sponsors: https://www.bravera.co/#{challenge_slug}/#{participant_slug}")
    |> text_body("Thanks for joining!")
  end

  def donation_charged(recipient, donation_params) do
    %{"amount" => amount, "challenge" => challenge, "participant" => participant} = donation_params

    new_email()
    |> to(recipient)
    |> from("no-reply@bravera.co")
    |> subject("Donation Charged")
    |> html_body("Your donation of #{amount} in sponsorship of #{participant} has been charged. Thank you for participating in the #{challenge}!")
    |> text_body("Your donation of #{amount} in sponsorship of #{participant} has been charged. Thank you for participating in the #{challenge}!")
  end

  def send_reset_email(recipient, token) do
    new_email()
    |> to(recipient)
    |> from("no-reply@bravera.co")
    |> subject("Reset Password Instructions")
    |> text_body("Please visit https://bravera.co/pass-reset/#{token}/edit to reset your password")
  end
end
