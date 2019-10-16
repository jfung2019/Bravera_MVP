defmodule OmegaBravera.Fundraisers.NgoOptions do
  @available_activities ["Run", "Cycle", "Walk", "Hike"]
  @available_distances %{
    3 => %{"1" => 0, "2" => 1, "3" => 2, "4" => 3},
    5 => %{"1" => 0, "2" => 2, "3" => 4, "4" => 5},
    6 => %{"1" => 0, "2" => 2, "3" => 4, "4" => 6},
    7 => %{"1" => 0, "2" => 2, "3" => 3, "4" => 7},
    8 => %{"1" => 0, "2" => 2, "3" => 5, "4" => 8},
    10 => %{"1" => 0, "2" => 3, "3" => 7, "4" => 10},
    15 => %{"1" => 0, "2" => 5, "3" => 10, "4" => 15},
    20 => %{"1" => 0, "2" => 5, "3" => 15, "4" => 20},
    25 => %{"1" => 0, "2" => 8, "3" => 18, "4" => 25},
    30 => %{"1" => 0, "2" => 10, "3" => 20, "4" => 30},
    35 => %{"1" => 0, "2" => 10, "3" => 20, "4" => 35},
    40 => %{"1" => 0, "2" => 10, "3" => 25, "4" => 40},
    50 => %{"1" => 0, "2" => 15, "3" => 25, "4" => 50},
    70 => %{"1" => 0, "2" => 20, "3" => 40, "4" => 70},
    75 => %{"1" => 0, "2" => 25, "3" => 45, "4" => 75},
    80 => %{"1" => 0, "2" => 30, "3" => 50, "4" => 80},
    90 => %{"1" => 0, "2" => 30, "3" => 60, "4" => 90},
    100 => %{"1" => 0, "2" => 35, "3" => 65, "4" => 100},
    120 => %{"1" => 0, "2" => 40, "3" => 80, "4" => 120},
    150 => %{"1" => 0, "2" => 50, "3" => 100, "4" => 150},
    200 => %{"1" => 0, "2" => 50, "3" => 125, "4" => 200},
    250 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 250},
    300 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 300},
    400 => %{"1" => 0, "2" => 100, "3" => 250, "4" => 400},
    500 => %{"1" => 0, "2" => 150, "3" => 350, "4" => 500},
    600 => %{"1" => 0, "2" => 200, "3" => 400, "4" => 600},
    750 => %{"1" => 0, "2" => 250, "3" => 450, "4" => 750},
    800 => %{"1" => 0, "2" => 250, "3" => 550, "4" => 800},
    1000 => %{"1" => 0, "2" => 200, "3" => 500, "4" => 1000},
    1500 => %{"1" => 0, "2" => 350, "3" => 850, "4" => 1500},
    1600 => %{"1" => 0, "2" => 500, "3" => 1000, "4" => 1600},
    2000 => %{"1" => 0, "2" => 650, "3" => 1250, "4" => 2000},
    2400 => %{"1" => 0, "2" => 1800, "3" => 1600, "4" => 2400},
    2500 => %{"1" => 0, "2" => 750, "3" => 1750, "4" => 2500},
    3200 => %{"1" => 0, "2" => 1066, "3" => 2133, "4" => 3200}
  }
  @available_durations [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    35,
    40,
    45,
    50,
    60,
    70,
    80,
    90,
    100,
    120
  ]
  @per_km "PER_KM"
  @per_milestone "PER_MILESTONE"
  @bravera_segment "BRAVERA_SEGMENT"

  @available_challenge_type_options [
    [key: "Per Goal", value: @per_milestone],
    [key: "Per KM", value: @per_km],
    [key: "Bravera Segment", value: @bravera_segment]
  ]

  @available_challenge_types [@per_milestone, @per_km, @bravera_segment]

  @available_currency_options %{
    "Hong Kong Dollar (HKD)" => "hkd",
    "South Korean Won (KRW)" => "krw",
    "Singapore Dollar (SGD)" => "sgd",
    "Malaysian Ringgit (MYR)" => "myr",
    "United States Dollar (USD)" => "usd",
    "British Pound (GBP)" => "gbp"
  }

  def activity_options, do: @available_activities

  def distance_options, do: Map.keys(@available_distances) |> Enum.sort()

  def duration_options, do: @available_durations

  def challenge_type_options, do: @available_challenge_types

  def challenge_type_options_human, do: @available_challenge_type_options

  def milestone_distances(target), do: Map.get(@available_distances, target)

  def currency_options, do: Map.values(@available_currency_options)

  def currency_options_human, do: @available_currency_options
end
