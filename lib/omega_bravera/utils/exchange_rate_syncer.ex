defmodule OmegaBravera.ExchangeRateSyncer do
  require Logger

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Money.Donation

  def sync do
    non_hkd_donations = get_non_hkd_donations()

    for donation <- non_hkd_donations do
      charge_params = %{
        "expand[]" => "balance_transaction"
      }

      case Stripy.req(:get, "charges/#{donation.charge_id}", charge_params) do
        {:ok, response} ->
          %{body: response_body} = response
          body = Poison.decode!(response_body)

          cond do
            body["balance_transaction"] ->
              Logger.info(fn ->
                "Exchange Rate Syncer: Stripe get charge successful. Charge Exchange Rate: #{inspect(body["balance_transaction"])}"
              end)

              donation_updated =
                Ecto.Changeset.change(
                  donation,
                  exchange_rate: Decimal.new(body["balance_transaction"]["exchange_rate"])
                )

              case Repo.update(donation_updated) do
                {:ok, _} ->
                  Logger.info(fn ->
                    "Exchange Rate Syncer: Successfully updated donation with exchange rate."
                  end)

                {:error, reason} ->
                  Logger.info(fn ->
                    "Exchange Rate Syncer: failed to update donation with exchange rate. Reason: #{inspect(reason)}"
                  end)
              end

            body["error"] ->
              Logger.error(fn ->
                "Exchange Rate Syncer: Stripe get charge failed: #{inspect(body["error"]["message"])}"
              end)

              :error
          end

        {:error, reason} ->
          Logger.error(fn ->
            "Exchange Rate Syncer: Stripe request failed: #{inspect(reason)}"
          end)

          :error
      end
    end
  end

  defp get_non_hkd_donations(),
    do:
      from(
        d in Donation,
        where: d.currency != "hkd" and d.status == "charged"
      )
      |> Repo.all()
end
