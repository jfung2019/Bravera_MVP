defmodule OmegaBravera.Offers.OfferApproval do
  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :offer_id, :integer
    field :status, Ecto.Enum, values: [:approved, :denied]
    field :message, :string
  end

  def changeset(offer_approval, attrs) do
    offer_approval
    |> cast(attrs, [:offer_id, :status, :message])
    |> validate_required([:offer_id, :status])
    |> validate_status()
  end

  defp validate_status(changeset) do
    case get_field(changeset, :status) do
      :denied ->
        validate_required(changeset, [:message])

      _ ->
        changeset
    end
  end
end
