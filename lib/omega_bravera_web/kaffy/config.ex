defmodule OmegaBraveraWeb.Kaffy.Config do
  def create_resources(_conn) do
    [
      accounts: [
        resources: [
          partner_user: [
            schema: OmegaBravera.Accounts.PartnerUser,
            admin: OmegaBraveraWeb.Kaffy.PartnerUserAdmin
          ]
        ]
      ],
      group: [
        resources: [
          group: [
            schema: OmegaBravera.Groups.Partner,
            admin: OmegaBraveraWeb.Kaffy.GroupAdmin
          ],
          group_location: [
            schema: OmegaBravera.Groups.PartnerLocation,
            admin: OmegaBraveraWeb.Kaffy.GroupLocationAdmin
          ]
        ]
      ],
      offer: [
        name: "Offers & Rewards",
        resources: [
          offer_vendor: [
            schema: OmegaBravera.Offers.OfferVendor,
            admin: OmegaBraveraWeb.Kaffy.OfferVendorAdmin
          ],
          offer: [
            schema: OmegaBravera.Offers.Offer,
            admin: OmegaBraveraWeb.Kaffy.OfferAdmin
          ]
        ]
      ]
    ]
  end
end
