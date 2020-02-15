defmodule OmegaBraveraWeb.ApiView do
  use OmegaBraveraWeb, :view

  def render("signature.json", %{
    fileURL: file_url,
    uploadURL: upload_url,
    originalFilename: original_filename
  }),
      do: %{fileURL: file_url, uploadURL: upload_url, originalFilename: original_filename}
end