defmodule OmegaBravera.Challenges.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Challenges.NGOChal}

  @allowed_attributes [:name, :slug, :challenge_id, :user_id, :count]
  @required_attributes [:name, :user_id]
  @update_attributes [
    :invite_tokens,
    :sent_invite_tokens,
    :invitations_accepted
  ]

  @derive {Phoenix.Param, key: :slug}
  schema "teams" do
    field(:name, :string)
    field(:slug, :string)
    field(:count, :integer, default: 1)
    field(:invite_tokens, {:array, :string})
    field(:sent_invite_tokens, {:array, :string})
    field(:invitations_accepted, :integer, default: 0)

    belongs_to(:user, User)
    belongs_to(:challenge, NGOChal)
    many_to_many(:users, User, join_through: "team_members")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> add_slug()
    |> add_invite_tokens()
    |> unique_constraint(:slug, name: :teams_slug_index)
  end

  def update_changeset(team, attrs) do
    team |> cast(attrs, @update_attributes)
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

  def add_invite_tokens(%Ecto.Changeset{} = changeset) do
    invite_tokens = get_field(changeset, :invites_tokens)
    # Subtract challenge owner from total team members.
    count = get_field(changeset, :count) - 1

    case invite_tokens do
      nil ->
        changeset
        |> Ecto.Changeset.change(%{
          invite_tokens: Enum.map(1..count, fn _ -> gen_unique_string(32) end)
        })

      _ ->
        changeset
    end
  end

  defp gen_slug(name) when is_nil(name), do: "#{gen_unique_string(32)}"
  defp gen_slug(name) when not is_nil(name), do: "#{Slug.slugify(name)}-#{gen_unique_string()}"

  defp gen_unique_string(length \\ 4),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
