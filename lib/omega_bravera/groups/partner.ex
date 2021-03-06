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
    field :approval_status, Ecto.Enum, values: [:approved, :denied, :pending], default: :pending
    field :approval_status_string, :string, load_in_query: false, source: :approval_status
    field :email_restriction, :string
    field :type, :string, virtual: true
    field :is_member, :boolean, virtual: true
    field :is_muted, :boolean, virtual: true
    has_one :location, PartnerLocation
    has_many :offer_partners, OfferPartner
    has_many :offers, through: [:offer_partners, :offer]
    has_many :votes, PartnerVote
    has_many :members, Member
    has_many :users, through: [:members, :user]
    has_many :chat_messages, ChatMessage, foreign_key: :group_id, references: :id
    belongs_to :organization, OmegaBravera.Accounts.Organization, type: :binary_id
    belongs_to :group_area, OmegaBravera.Locations.Location, foreign_key: :location_id

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
      :approval_status,
      :join_password,
      :email,
      :website,
      :organization_id,
      :phone,
      :email_restriction,
      :location_id
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:website, max: 255)
    |> validate_length(:phone, max: 255)
    |> validate_length(:join_password, max: 255, min: 4)
    |> validate_format(:website, ~r/^(https|http):\/\/\w+/)
    |> validate_required([:name, :introduction, :short_description, :images])
    |> validate_inclusion(:approval_status, available_approval_status())
  end

  def org_changeset(partner, attrs) do
    changeset(partner, attrs)
    |> validate_required([:organization_id])
    |> validate_enquiry_method()
  end

  def available_approval_status, do: Ecto.Enum.values(__MODULE__, :approval_status)

  defp validate_enquiry_method(changeset) do
    with password when is_binary(password) <- get_field(changeset, :join_password),
         nil <- get_field(changeset, :email),
         nil <- get_field(changeset, :website),
         nil <- get_field(changeset, :phone) do
      error = "Must fill out either an email, website, or phone number when group is private."

      changeset
      |> add_error(:email, error)
      |> add_error(:website, error)
      |> add_error(:phone, error)
    else
      _ ->
        changeset
    end
  end
end
