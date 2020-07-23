defmodule OmegaBravera.Partners.Partner do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Partners.{PartnerLocation, PartnerVote, Member}

  schema "partners" do
    field :images, {:array, :string}, default: []
    field :introduction, :string
    field :name, :string
    field :opening_times, :string
    field :live, :boolean, default: false
    field :type, :string, virtual: true
    has_one :location, PartnerLocation
    has_many :offers, OmegaBravera.Offers.Offer
    has_many :votes, PartnerVote
    has_many :members, Member

    timestamps()
  end

  @doc false
  def changeset(partner, attrs) do
    partner
    |> cast(attrs, [:name, :introduction, :opening_times, :images, :live])
    |> validate_length(:name, max: 255)
    |> validate_required([:name, :introduction, :opening_times, :images])
  end
end
