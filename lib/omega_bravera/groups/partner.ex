defmodule OmegaBravera.Groups.Partner do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Groups.{PartnerLocation, PartnerVote, Member, OfferPartner, ChatMessage}

  schema "partners" do
    field :images, {:array, :string}, default: []
    field :introduction, :string
    field :name, :string
    field :short_description, :string
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
    has_many :users, through: [:members, :user]
    has_many :chat_messages, ChatMessage, foreign_key: :group_id, references: :id
    belongs_to :organization, OmegaBravera.Accounts.Organization, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(partner, attrs) do
    partner
    |> cast(attrs, [
      :name,
      :introduction,
      :short_description,
      :images,
      :live,
      :join_password,
      :email,
      :website,
      :organization_id,
      :phone
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:website, max: 255)
    |> validate_length(:phone, max: 255)
    |> validate_length(:join_password, max: 255, min: 4)
    |> validate_format(:website, ~r/^(https|http):\/\/\w+/)
    |> validate_required([:name, :introduction, :short_description, :images])
  end
end
