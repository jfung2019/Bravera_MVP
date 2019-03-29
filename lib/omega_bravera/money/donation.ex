defmodule OmegaBravera.Money.Donation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Accounts.Donor
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
    field(:km_distance, :integer)
    field(:donor_pays_fees, :boolean, default: false)

    # charge successful fields
    field(:charge_id, :string)
    field(:last_digits, :string)
    field(:card_brand, :string)
    field(:charged_description, :string)
    field(:charged_status, :string)
    field(:charged_amount, :decimal)
    field(:charged_at, :utc_datetime)
    field(:exchange_rate, :decimal, default: 1)

    # associations
    belongs_to(:user, User)
    belongs_to(:donor, Donor)
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
    :km_distance,
    :user_id,
    :ngo_chal_id,
    :ngo_id,
    :exchange_rate,
    :donor_pays_fees,
    :donor_id
  ]
  @required_attributes [
    :amount,
    :currency,
    :str_src,
    :str_cus_id,
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

  def charge_changeset(%__MODULE__{} = donation, stripe_attributes, nil) do
    change(donation, Map.merge(charged_attributes(stripe_attributes), %{status: "charged"}))
  end

  def charge_changeset(%__MODULE__{} = donation, stripe_attributes, exchange_rate) do
    change(
      donation,
      Map.merge(charged_attributes(stripe_attributes, exchange_rate), %{status: "charged"})
    )
  end

  def failed_to_charge_changeset(%__MODULE__{} = donation) do
    change(donation, %{status: "failed"})
  end

  defp charged_attributes(stripe_attributes, %Decimal{} = exchange_rate \\ Decimal.new(1)) do
    %{
      charge_id: stripe_attributes["id"],
      last_digits: get_in(stripe_attributes, ["source", "card", "last4"]),
      card_brand: get_in(stripe_attributes, ["source", "card", "brand"]),
      charged_description: stripe_attributes["description"],
      charged_status: stripe_attributes["status"],
      charged_amount: moneyfied_stripe_amount(stripe_attributes["amount"]),
      charged_at: DateTime.from_unix!(stripe_attributes["created"]),
      exchange_rate: exchange_rate
    }
  end

  defp moneyfied_stripe_amount(amount), do: Decimal.from_float(amount / 100)
end
