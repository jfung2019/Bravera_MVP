defmodule OmegaBravera.Repo.Migrations.UpdateImagesInOffers do
  use Ecto.Migration

  def change do
    execute "UPDATE offers SET images = array_append(images, image)"
  end
end
