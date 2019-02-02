defmodule OmegaBravera.Fundraisers.NgoOptions do
  @available_activities ["Run", "Cycle", "Walk", "Hike"]
  @available_distances %{
    50 => %{"1" => 0, "2" => 15, "3" => 25, "4" => 50},
    75 => %{"1" => 0, "2" => 25, "3" => 45, "4" => 75},
    100 => %{"1" => 0, "2" => 35, "3" => 65, "4" => 100},
    150 => %{"1" => 0, "2" => 50, "3" => 100, "4" => 150},
    200 => %{"1" => 0, "2" => 50, "3" => 125, "4" => 200},
    250 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 250},
    300 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 300},
    400 => %{"1" => 0, "2" => 100, "3" => 250, "4" => 400},
    500 => %{"1" => 0, "2" => 150, "3" => 350, "4" => 500},
    750 => %{"1" => 0, "2" => 250, "3" => 450, "4" => 750},
    1000 => %{"1" => 0, "2" => 200, "3" => 500, "4" => 1000},
    1500 => %{"1" => 0, "2" => 350, "3" => 850, "4" => 1500},
    2000 => %{"1" => 0, "2" => 650, "3" => 1250, "4" => 2000},
    2500 => %{"1" => 0, "2" => 750, "3" => 1750, "4" => 2500}
  }
  @available_durations [20, 24, 25, 26, 27, 28, 29, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 120]
  @per_km "PER_KM"
  @per_milestone "PER_MILESTONE"

  @available_challenge_type_options [
    [key: "Per Goal", value: @per_milestone],
    [key: "Per KM", value: @per_km]
  ]

  @available_challenge_types [@per_milestone, @per_km]

  @available_currency_options %{
    "Hong Kong Dollar (HKD)" => "hkd",
    "South Korean Won (KRW)" => "krw",
    "Singapore Dollar (SGD)" => "sgd",
    "Malaysian Ringgit (MYR)" => "myr",
    "United States Dollar (USD)" => "usd",
    "British Pound (GBP)" => "gbp"
  }

  def activity_options, do: @available_activities

  def distance_options, do: Map.keys(@available_distances)

  def duration_options, do: @available_durations

  def challenge_type_options, do: @available_challenge_types

  def challenge_type_options_human, do: @available_challenge_type_options

  def milestone_distances(target), do: Map.get(@available_distances, target)

  def currency_options, do: Map.values(@available_currency_options)

  def currency_options_human, do: @available_currency_options
end