defmodule OmegaBravera.KaffyConfig do
  def create_resources(_conn) do
    [
      accounts: [
        resources: [
          partner_user: [
            schema: OmegaBravera.Accounts.PartnerUser,
            admin: OmegaBravera.Kaffy.PartnerUser
          ]
        ]
      ],
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
