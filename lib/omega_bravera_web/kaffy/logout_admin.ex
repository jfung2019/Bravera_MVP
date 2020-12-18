defmodule OmegaBravera.LogoutAdmin do
  def custom_links(_schema) do
    [
      %{
        name: "Source Code",
        url: "https://example.com/repo/issues",
        order: 2,
        location: :top,
        icon: "paperclip"
      }
    ]
  end
end
