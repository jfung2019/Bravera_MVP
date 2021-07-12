defmodule OmegaBraveraWeb.Api.Types.Activity do
  use Absinthe.Schema.Notation

  object :activity do
    field :id, :id
    field :device, :device
    field :name, :string
    field :step_count, :integer
    field :distance, :decimal
    field :start_date, :date
    field :end_date, :date
    field :source, :string
    field :type, :string
  end

  object :save_activity_result do
    field :activity, :activity
  end

  input_object :save_activity_input do
    field :distance, :decimal
    field :start_date, :date
    field :end_date, :date
    field :source, :string
    field :type, :string
  end

  enum :insight_period do
    value :weekly
    value :monthly
    value :yearly
  end

  object :activity_insight_result do
    field :distance_by_date, list_of(non_null(:distance_by_date))
    field :average_distance, non_null(:float)
    field :total_distance, non_null(:float)
    field :distance_compare, non_null(:float)
  end

  object :distance_by_date do
    field :date, non_null(:date)
    field :distance, non_null(:float)
  end
end
