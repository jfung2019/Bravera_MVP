defmodule OmegaBravera.Money.Donation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Fundraisers.NGO

  # TODO do we need str_source or str_customer here ?
  # I think we do...

  schema "donations" do
    field(:amount, :decimal)
    field(:currency, :string)
    field(:milestone, :integer)
    field(:status, :string, default: "pending")
    field(:str_src, :string)
    field(:str_cus_id, :string)
    field(:milestone_distance, :integer)

    # charge successful fields
    field(:charge_id, :string)
    field(:last_digits, :string)
    field(:card_brand, :string)
    field(:charged_description, :string)
    field(:charged_status, :string)
    field(:charged_amount, :decimal)
    field(:charged_at, :utc_datetime)

    # associations
    belongs_to(:user, User)
    belongs_to(:ngo_chal, NGOChal)
    belongs_to(:ngo, NGO)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :amount,
    :currency,
    :str_src,
    :str_cus_id,
    :milestone,
    :status,
    :milestone_distance,
    :user_id,
    :ngo_chal_id,
    :ngo_id
  ]
  @required_attributes [
    :amount,
    :currency,
    :str_src,
    :str_cus_id,
    :milestone,
    :status,
    :user_id,
    :ngo_chal_id,
    :ngo_id
  ]

  @doc false
  def changeset(donation, attrs) do
    donation
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
  end

  def charge_changeset(%__MODULE__{} = donation, stripe_attributes) do
    change(donation, Map.merge(charged_attributes(stripe_attributes), %{status: "charged"}))
  end

  defp charged_attributes(stripe_attributes) do
    %{
      charge_id: stripe_attributes["id"],
      last_digits: get_in(stripe_attributes, ["source", "card", "last4"]),
      card_brand: get_in(stripe_attributes, ["source", "card", "brand"]),
      charged_description: stripe_attributes["description"],
      charged_status: stripe_attributes["status"],
      charged_amount: moneyfied_stripe_amount(stripe_attributes["amount"]),
      charged_at: DateTime.from_unix!(stripe_attributes["created"])
    }
  end

  defp moneyfied_stripe_amount(amount), do: Decimal.new(amount / 100)
end
