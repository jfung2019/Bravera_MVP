defmodule OmegaBravera.Offers.OfferChallengeTeam do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Offers.OfferChallenge}

  @allowed_attributes [:name, :count]
  @required_attributes [:name]

  @derive {Phoenix.Param, key: :slug}
  schema "offer_challenge_teams" do
    field :count, :integer
    field :name, :string
    field :slug, :string

    belongs_to(:user, User)
    belongs_to(:offer_challenge, OfferChallenge)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%__MODULE__{} = offer_challenge_team, %User{} = user, attrs \\ %{}) do
    offer_challenge_team
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> add_slug()
    |> put_change(:user_id, user.id)
    |> validate_required([:user_id])
    |> unique_constraint(:slug, name: :offer_challenge_teams_slug_index)
  end

  def add_slug(%Ecto.Changeset{} = changeset) do
    name = get_field(changeset, :name)
    slug = get_field(changeset, :slug)

    case slug do
      nil ->
        changeset
        |> Ecto.Changeset.change(%{
          slug: gen_slug(name)
        })

      _ ->
        changeset
    end
  end

  defp gen_slug(name) when is_nil(name), do: "#{gen_unique_string()}"
  defp gen_slug(name) when not is_nil(name), do: "#{Slug.slugify(name)}-#{gen_unique_string()}"

  defp gen_unique_string(length \\ 5),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
