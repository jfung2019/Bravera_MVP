defmodule OmegaBravera.OfferVendorAdmin do
  def index(_) do
    [
      vendor_id: nil,
      email: nil,
      cc: nil
    ]
  end

  def form_fields(_) do
    [
      vendor_id: %{label: "vendor_id*"},
      email: %{label: "email*"},
      cc: nil
    ]
  end
end