defmodule OmegaBraveraWeb.Api.Types.Offer do
  use Absinthe.Schema.Notation

  @desc "Offer type according to if they have online or in store offers"
  enum :offer_type do
    value :in_store, description: "In store offer that uses a QR code"

    value :online,
      description: "Online offer that can be redeemed from partner's website"
  end

  object :offer do
    field :id, non_null(:integer)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :toc, non_null(:string)

    field :logo, :string,
      resolve: fn _parent, %{source: %{images: images}} ->
        {:ok, Enum.at(images, 0)}
      end

    field :image, :string,
      resolve: fn _parent, %{source: %{images: images}} ->
        {:ok, Enum.at(images, 0)}
      end

    field :images, non_null(list_of(:string))
    field :target, non_null(:integer)
    field :end_date, non_null(:date)
    field :desc, :string, resolve: fn _parent, %{source: %{desc: desc}} -> {:ok, to_string(desc)} end
    field :offer_type, non_null(:offer_type)
    field :offer_challenge_types, non_null(list_of(:string))
    field :offer_challenges, list_of(:offer_challenge)
    field :take_challenge, non_null(:boolean)
    field :payment_amount, :decimal
    field :currency, :string
    field :external_terms_url, :string
    field :accept_terms_text, :string
    field :form_url, :string
  end
end
