defmodule OmegaBraveraWeb.Api.UploadAuth do
  @salt "upload salt"
  @context OmegaBraveraWeb.Endpoint

  def generate_offer_token(offer_id),
    do: Phoenix.Token.sign(@context, @salt, {:offer_id, offer_id})

  def generate_partner_token(partner_id),
    do: Phoenix.Token.sign(@context, @salt, {:partner_id, partner_id})

  def decrypt_token(token), do: Phoenix.Token.verify(@context, @salt, token, max_age: 86400)
end
