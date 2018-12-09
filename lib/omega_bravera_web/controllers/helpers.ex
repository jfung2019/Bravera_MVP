defmodule OmegaBraveraWeb.Controllers.Helpers do
  alias OmegaBravera.Money
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Challenges

  def total_for_user_challenges(ngo_chals, type) do
    cond do
      Enum.empty?(ngo_chals) ->
        0

      true ->
        ngo_chals
        |> Enum.map(fn ngo_chal ->
          get_stats(ngo_chal)
          |> get_in(["total", type])
          |> add_currency(ngo_chal.default_currency)
        end)
        |> total_with_currency()
        |> total_to_string()
    end
  end

  defp add_currency(total, currency), do: %{currency: currency, total: total}

  defp total_with_currency(total) do
    currencies = %{"hkd" => 0, "krw" => 0, "sgd" => 0, "myr" => 0, "usd" => 0, "gbp" => 0}

    Enum.reduce(total, currencies, fn d, acc ->
      total = d[:total]
      Map.update(acc, d[:currency], total, fn sum -> sum + total end)
    end)
    |> Enum.filter(fn {_currency, total} -> total > 0 end)
    |> Enum.into(%{})
  end

  defp total_to_string(total_map) when total_map == %{}, do: "0"

  defp total_to_string(total_map) do
    Enum.reduce(total_map, "", fn
      el, acc ->
        "#{String.upcase(elem(el, 0))}: #{elem(el, 1)} " <> acc
    end)
  end

  def get_stats(%NGOChal{type: "PER_MILESTONE"} = ngo_chal) do
    ngo_chal
    |> Money.milestones_donations()
    |> Enum.map(fn {k, v} ->
      {to_string(k), Enum.into(Enum.map(v, fn {kk, vv} -> {kk, Decimal.to_integer(vv)} end), %{})}
    end)
    |> total_the_pledged_amount()
    |> Enum.into(%{})
  end

  def get_stats(%NGOChal{type: "PER_KM"} = ngo_chal) do
    ngo_chal = OmegaBravera.Challenges.get_ngo_chal!(ngo_chal.id)
    total_secured = Challenges.get_per_km_challenge_total_secured(ngo_chal.slug)
    total_pledged = Challenges.get_per_km_challenge_total_pledges(ngo_chal.slug)
    total = %{"total" => %{"charged" => 0, "pending" => 0}}

    total =
      if Decimal.decimal?(total_secured) do
        put_in(
          total,
          ["total", "charged"],
          Decimal.to_float(total_secured) |> trunc()
        )
      else
        total
      end

    total =
      if Decimal.decimal?(total_pledged) do
        put_in(
          total,
          ["total", "pending"],
          Decimal.mult(total_pledged, ngo_chal.distance_target)
          |> Decimal.to_float()
          |> trunc()
        )
      else
        total
      end

    total
  end

  defp total_the_pledged_amount(tuple_list) do
    [
      {"total",
       Enum.reduce(tuple_list, %{"pending" => 0, "charged" => 0}, fn
         {_, %{"total" => total, "charged" => charged}},
         %{"pending" => total_acc, "charged" => total_charged} ->
           %{"pending" => total + total_acc, "charged" => charged + total_charged}

         # Catch if no match
         _, acc ->
           acc
       end)}
      | tuple_list
    ]
  end
end
