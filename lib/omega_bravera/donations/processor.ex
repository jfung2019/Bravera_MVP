defmodule OmegaBravera.Donations.Processor do
  alias OmegaBravera.{Fundraisers.NGO, Challenges.NGOChal, Money, Accounts.User, StripeHelpers}


  def handle_donation(%User{} = current_user, %NGO{} = ngo, %NGOChal{id: challenge_id}, donation_params, stripe_customer, milestones) do
    %{"str_src" => str_src, "currency" => currency, "email" => email} = donation_params

    charge_result = StripeHelpers.charge_stripe_customer(ngo, charge_params(stripe_customer, donation_params), challenge_id)

    case charge_result do
      {:ok, %{body: response_body}} ->
        parsed_response = Poison.decode!(response_body)

        require IEx
        IEx.pry

        cond do
          parsed_response["source"] ->
            rel_params = %{user_id: current_user.id, ngo_chal_id: challenge_id, ngo_id: ngo.id}
            case Money.create_donations(rel_params, milestones, donation_params["kickstarter"], currency, str_src, stripe_customer["id"]) do
              {:ok, _response} ->
                {:ok, :donation_and_pledges_created}
              :error ->
                {:error, :donation_model_couldnt_be_created}
            end

          parsed_response["error"] ->
            {:error, :stripe_api_error}
          true ->
            {:ok, :donation_and_pledges_created}
        end
      :error ->
        {:error, :stripe_api_error}
    end
  end

  def charge_params(stripe_customer, params) do
    %{
      "amount" => params["kickstarter"],
      "currency" => params["currency"],
      "source" => params["str_src"],
      "receipt_email" => params["email"],
      "customer" => stripe_customer["id"]
    }
  end
end
