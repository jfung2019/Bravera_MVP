defmodule OmegaBravera.Partners.Partner do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Partners.{PartnerLocation, PartnerVote, Member, OfferPartner}

  schema "partners" do
    field :images, {:array, :string}, default: []
    field :introduction, :string
    field :name, :string
    field :opening_times, :string
    field :join_password, :string
    field :email, :string
    field :website, :string
    field :phone, :string
    field :live, :boolean, default: false
    field :type, :string, virtual: true
    field :is_member, :boolean, virtual: true
    has_one :location, PartnerLocation
    has_many :offer_partners, OfferPartner
    has_many :offers, through: [:offer_partners, :offer]
    has_many :votes, PartnerVote
    has_many :members, Member

    timestamps()
  end

  @doc false
  def changeset(partner, attrs) do
    partner
    |> cast(attrs, [
      :name,
      :introduction,
      :opening_times,
      :images,
      :live,
      :join_password,
      :email,
      :website,
      :phone
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:website, max: 255)
    |> validate_length(:phone, max: 255)
    |> validate_length(:join_password, max: 255, min: 4)
    |> validate_format(:website, ~r/^(https|http):\/\/\w+/)
    |> validate_required([:name, :introduction, :opening_times, :images])
  end
end
