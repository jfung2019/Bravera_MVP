defmodule OmegaBravera.ImageHelper do
  def swap_images(images, _original_index, new_index) when length(images) == new_index,
       do: images

  def swap_images(images, 0, new_index) when new_index < 0, do: images

  def swap_images(images, original_index, new_index) do
    original_image = Enum.at(images, original_index)
    other_image = Enum.at(images, new_index)

    images
    |> List.replace_at(new_index, original_image)
    |> List.replace_at(original_index, other_image)
  end
end