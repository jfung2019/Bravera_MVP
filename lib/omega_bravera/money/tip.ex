defmodule OmegaBravera.Money.Tip do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  schema "tips" do
    field :amount, :integer
    field :currency, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(tip, attrs) do
    tip
    |> cast(attrs, [:amount, :currency])
    |> validate_required([:amount, :currency])
  end
end
