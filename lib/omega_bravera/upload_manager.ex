defmodule OmegaBravera.UploadManager do
  def presigned_url(file_path, filename, mime_type) do
    {:ok, upload_url} =
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(
        :put,
        Application.get_env(:omega_bravera, :images_bucket_name),
        file_path,
        query_params: [
          {"ContentType", mime_type},
          {"Key", filename}
        ]
      )

    {:ok, upload_url,
     Path.join([Application.get_env(:omega_bravera, :images_cdn_url), file_path])}
  end
end
