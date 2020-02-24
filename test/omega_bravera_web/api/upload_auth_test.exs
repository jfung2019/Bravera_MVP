defmodule OmegaBraveraWeb.Api.UploadAuthTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBraveraWeb.Api.UploadAuth

  test "can generate a token that can be decrypted to get the offer_id" do
    token = UploadAuth.generate_offer_token(1)
    assert {:ok, {:offer_id, 1}} = UploadAuth.decrypt_token(token)
  end
end
