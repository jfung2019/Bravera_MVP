defmodule OmegaBraveraWeb.Api.Types.Activity do
  use Absinthe.Schema.Notation

  object :activity do
    field(:id, :id)
    field(:device, :device)
    field(:name, :string)
    field(:distance, :decimal)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:source, :string)
  end

  object :save_activity_result do
    field(:activity, :activity)
  end

  input_object :save_activity_input do
    field(:distance, :decimal)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:source, :string)
  end
end
