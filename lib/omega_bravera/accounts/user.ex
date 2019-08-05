defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.{Credential, Setting}
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.{NGOChal, Team}
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Stripe.StrCustomer
  alias OmegaBravera.Offers.{OfferChallenge, OfferChallengeTeam}

  @required_attributes [:firstname, :lastname, :location_id]
  @allowed_attributes [
    :email,
    :firstname,
    :lastname,
    :additional_info,
    :email_verified,
    :profile_picture,
    :accept_terms,
    :location_id
  ]

  schema "users" do
    field(:email, :string)
    field(:email_verified, :boolean, default: false)
    field(:email_activation_token, :string)
    field(:firstname, :string)
    field(:lastname, :string)
    field(:additional_info, :map, default: %{})
    field(:profile_picture, :string, default: nil)
    field(:accept_terms, :boolean, virtual: true)

    # associations
    has_one(:credential, Credential)
    has_one(:strava, Strava)
    has_one(:setting, Setting)
    has_many(:ngos, NGO)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)
    has_many(:str_customers, StrCustomer)
    has_many(:subscribed_email_categories, OmegaBravera.Emails.UserEmailCategories)
    has_many(:offer_challenges, OfferChallenge)
    belongs_to :location, OmegaBravera.Locations.Location

    many_to_many(:teams, Team, join_through: "team_members")

    many_to_many(
      :offer_teams,
      OfferChallengeTeam,
      join_through: "offer_team_members",
      join_keys: [user_id: :id, team_id: :id]
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email)
    |> add_email_activation_token()
    |> cast_assoc(:setting, with: &Setting.changeset/2)
    |> cast_assoc(:credential, with: &Credential.optional_changeset/2, required: false)
  end

  def create_credential_user_changeset(user, attrs \\ %{credential: %{}}) do
    user
    |> changeset(attrs)
    |> validate_required([:email, :accept_terms])
    |> validate_acceptance(:accept_terms)
    |> cast_assoc(:credential, with: &Credential.changeset/2, required: true)
  end

  def update_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> email_changed(user)
  end

  def email_changed(%Ecto.Changeset{} = changeset, %__MODULE__{} = user) do
    new_email = get_field(changeset, :email)

    cond do
      new_email != user.email ->
        changeset
        |> put_change(:email_verified, false)
        |> put_change(:email_activation_token, gen_token())

      true ->
        changeset
    end
  end

  def update_profile_picture_changeset(user, attrs) do
    user
    |> cast(attrs, [:profile_picture])
  end

  def add_email_activation_token(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :email_activation_token) do
      nil ->
        changeset
        |> Ecto.Changeset.change(%{
          email_activation_token: gen_token()
        })

      _ ->
        changeset
    end
  end

  defp gen_token(length \\ 16),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)

  def full_name(%__MODULE__{firstname: first, lastname: last}), do: "#{first} #{last}"
end
