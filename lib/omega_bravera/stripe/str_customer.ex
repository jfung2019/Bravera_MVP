defmodule OmegaBravera.Stripe.StrCustomer do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  schema "str_customers" do
    field(:cus_id, :string)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(str_customer, attrs) do
    str_customer
    |> cast(attrs, [:cus_id])
    |> validate_required([:cus_id])
    |> unique_constraint(:cus_id)
  end
end
