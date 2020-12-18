defmodule OmegaBravera.KaffyConfig do
  def create_resources(_conn) do
    [
      offer: [
        resources: [
          offer_vendor: [
            schema: OmegaBravera.Offers.OfferVendor,
            admin: OmegaBravera.OfferVendorAdmin
          ]
        ]
      ]
    ]
  end
end
