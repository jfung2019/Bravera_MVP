defmodule OmegaBravera.Offers.OfferChallengeTeam do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Offers.{OfferChallenge, Offer, OfferChallengeTeamInvitation}

  @allowed_attributes [:name, :count]

  @derive {Phoenix.Param, key: :slug}
  schema "offer_challenge_teams" do
    field(:count, :integer)
    field(:name, :string)
    field(:slug, :string)

    belongs_to(:user, User)
    belongs_to(:offer_challenge, OfferChallenge)
    has_many(:invitations, OfferChallengeTeamInvitation, foreign_key: :team_id)

    many_to_many(:users, User,
      join_through: "offer_team_members",
      join_keys: [team_id: :id, user_id: :id]
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(
        %__MODULE__{} = offer_challenge_team,
        %Offer{} = offer,
        %User{} = user,
        attrs \\ %{}
      ) do
    offer_challenge_team
    |> cast(attrs, @allowed_attributes)
    |> add_slug()
    |> add_count(offer)
    |> add_name(user)
    |> put_change(:user_id, user.id)
    |> validate_required([:user_id])
    |> unique_constraint(:slug, name: :offer_challenge_teams_slug_index)
  end

  def add_slug(%Ecto.Changeset{} = changeset) do
    name = get_field(changeset, :name)

    change(changeset, %{slug: gen_slug(name)})
  end

  def add_count(%Ecto.Changeset{} = changeset, %Offer{} = offer) do
    count = get_field(changeset, :count)

    case count do
      nil ->
        change(changeset, %{count: offer.additional_members - 1})

      _ ->
        change(changeset, %{count: count})
    end
  end

  def add_name(%Ecto.Changeset{} = changeset, %User{} = user) do
    name = get_field(changeset, :name)

    case name do
      nil ->
        change(changeset, %{name: gen_slug(user.firstname)})

      _ ->
        change(changeset, %{name: name})
    end
  end

  defp gen_slug(name) when is_nil(name), do: "#{gen_unique_string()}"
  defp gen_slug(name) when not is_nil(name), do: "#{Slug.slugify(name)}-#{gen_unique_string()}"

  defp gen_unique_string(length \\ 5),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
