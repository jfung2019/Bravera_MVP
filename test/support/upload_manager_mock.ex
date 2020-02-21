defmodule OmegaBravera.UploadManagerMock do
  def presigned_url(path, _filename, _mime_type),
      do: {:ok, "https://upload.com/" <> path, "https://cdn.com/" <> path}
end