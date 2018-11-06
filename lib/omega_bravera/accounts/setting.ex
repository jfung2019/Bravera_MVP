defmodule OmegaBravera.Accounts.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

@allowed_attribs [:location, :weight, :date_of_birth, :gender, :user_id]
@gender_list ["Male", "Female", "Other"]

  schema "settings" do
    field(:location, :string)
    field(:weight, :integer, default: nil)
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

  def gender_options, do: @gender_list
end
