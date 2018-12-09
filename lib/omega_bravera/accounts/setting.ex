defmodule OmegaBravera.Accounts.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  @allowed_attribs [:location, :weight, :date_of_birth, :gender, :user_id]
  @gender_list ["Male", "Female", "Other"]

  schema "settings" do
    field(:location, :string)
    field(:weight, :decimal, default: nil)
    field(:date_of_birth, :date)
    field(:gender, :string, default: nil)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @allowed_attribs)
    |> validate_required([:user_id])
  end

  defp get_weight_whole_number(), do: Enum.to_list(30..130)

  defp get_weight_fraction(),
    do:
      Enum.map(0..9, fn x ->
        Decimal.new(x * 0.1) |> Decimal.round(1) |> Decimal.to_string()
      end)

  def weight_list, do: get_weight_whole_number()
  def weight_fraction_list, do: get_weight_fraction()
  def gender_options, do: @gender_list
end
