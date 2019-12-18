defmodule OmegaBravera.UploadManager do
  def presigned_url(path, filename, mime_type) do
    {:ok, upload_url} =
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(
        :put,
        Application.get_env(:omega_bravera, :images_bucket_name),
        path,
        query_params: [
          {"ContentType", mime_type},
          {"Key", filename}
        ]
      )

    {:ok, upload_url, Path.join([Application.get_env(:omega_bravera, :image_cdn_url), path])}
  end
end
