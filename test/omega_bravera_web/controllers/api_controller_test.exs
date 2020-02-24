defmodule OmegaBraveraWeb.ApiControllerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBraveraWeb.Api.UploadAuth

  test "a user with valid token can get a presigned URL and cdn URL", %{conn: conn} do
    token = UploadAuth.generate_offer_token(1)
    original_filename = "hello.jpg"

    conn =
      get(conn, Routes.api_path(conn, :presign), %{
        token: token,
        filename: original_filename,
        mimetype: "image/jpg"
      })

    assert %{
             "uploadURL" => "https://upload.com/offer_images/1/" <> filename,
             "fileURL" => "https://cdn.com/offer_images/1/" <> filename,
             "originalFilename" => ^original_filename
           } = json_response(conn, 200)

    assert ".jpg" = Path.extname(filename)
    assert {:ok, _} = Ecto.UUID.cast(Path.basename(filename, ".jpg"))
  end
end
