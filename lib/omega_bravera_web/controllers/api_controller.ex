defmodule OmegaBraveraWeb.ApiController do
  use OmegaBraveraWeb, :controller
  @upload_manager Application.get_env(:omega_bravera, :upload_manager)

  def presign(conn, %{"filename" => filename, "mimetype" => mime_type, "token" => token}) do
    case OmegaBraveraWeb.Api.UploadAuth.decrypt_token(token) do
      {:ok, {:offer_id, offer_id}} ->
        render_upload_response(conn, "offer_images", offer_id, mime_type, filename)
    end
  end

  defp render_upload_response(conn, dir, id, mime_type, filename) do
    path =
      Path.join([
        dir,
        Integer.to_string(id),
        Ecto.UUID.generate() <> Path.extname(filename)
      ])

    {:ok, upload_url, cdn_url} = @upload_manager.presigned_url(path, filename, mime_type)

    render(conn, "signature.json",
      uploadURL: upload_url,
      fileURL: cdn_url,
      originalFilename: filename
    )
  end
end
