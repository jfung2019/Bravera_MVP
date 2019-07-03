defmodule OmegaBravera.Accounts.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  @allowed_attribs [:location, :weight_fraction, :weight_whole, :date_of_birth, :gender, :user_id]
  @gender_list ["Male", "Female", "Other"]

  schema "settings" do
    field(:location, :string)
    field(:weight, :decimal, default: nil)
    field(:weight_fraction, :decimal, virtual: true, default: 0)
    field(:weight_whole, :integer, virtual: true, default: 0.0)
    field(:date_of_birth, :date)
    field(:gender, :string, default: nil)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @allowed_attribs)
    |> assemble_weight()
  end

  defp get_weight_whole_number(), do: Enum.to_list(30..130)

  defp get_weight_fraction(),
    do:
      Enum.map(0..9, fn x ->
        Decimal.from_float(x * 0.1) |> Decimal.round(1) |> Decimal.to_string()
      end)

  def weight_list, do: get_weight_whole_number()
  def weight_fraction_list, do: get_weight_fraction()
  def gender_options, do: @gender_list

  defp assemble_weight(%{changes: changes} = changeset) do
    cond do
      Map.has_key?(changes, :weight_whole) or Map.has_key?(changes, :weight_fraction) ->
        whole = get_field(changeset, :weight_whole)
        fraction = get_field(changeset, :weight_fraction)
        put_change(changeset, :weight, Decimal.add(whole, fraction))

      true ->
        changeset
    end
  end
end
