defmodule OmegaBravera.Groups.GroupApproval do
  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :group_id, :integer
    field :status, Ecto.Enum, values: [:approved, :denied]
    field :message, :string
  end

  def changeset(group_approval, attrs) do
    group_approval
    |> cast(attrs, [:group_id, :status, :message])
    |> validate_required([:group_id, :status])
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
