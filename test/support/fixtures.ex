defmodule OmegaBravera.Fixtures do
  alias OmegaBravera.Partners

  def partner_fixture(attrs \\ %{}) do
    {:ok, partner} =
      attrs
      |> Enum.into(%{
        images: [],
        introduction: "some introduction",
        name: "some name",
        opening_times: "some opening_times"
      })
      |> Partners.create_partner()

    partner
  end

  def partner_location_fixture(attrs \\ %{}) do
    {:ok, partner_location} =
      attrs
      |> Enum.into(%{address: "some address", latitude: "120.5", longitude: "120.5"})
      |> Partners.create_partner_location()

    partner_location
  end
end
