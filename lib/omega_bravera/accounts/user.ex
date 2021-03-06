defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Accounts.Shared

  alias OmegaBravera.Accounts.{Credential, Setting, PrivateChatMessage}
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.{NGOChal, Team}
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Stripe.StrCustomer
  alias OmegaBravera.Offers.{OfferChallenge, OfferChallengeTeam}

  @required_attributes [
    :firstname,
    :lastname,
    :username,
    :location_id,
    :locale,
    :email,
    :sync_type
  ]
  @allowed_attributes [
    :email,
    :firstname,
    :lastname,
    :username,
    :additional_info,
    :email_verified,
    :profile_picture,
    :accept_terms,
    :location_id,
    :locale,
    :referred_by_id,
    :last_login_datetime,
    :sync_type
  ]

  schema "users" do
    field :email, :string
    field :email_verified, :boolean, default: false
    field :email_activation_token, :string
    field :firstname, :string
    field :lastname, :string
    field :username, :string
    field :locale, :string, default: "en"
    field :sync_type, Ecto.Enum, values: [:device, :strava, :pedometer], default: :device
    field :new_email, :string
    field :new_email_verification_code, :string

    # Admin section fields
    field :active, :boolean, virtual: true
    field :device_type, :string, virtual: true
    field :number_of_rewards, :integer, virtual: true
    field :number_of_claimed_rewards, :integer, virtual: true

    # Represents KMs
    field :daily_points_limit, :integer, default: 8
    field :additional_info, :map, default: %{}
    field :profile_picture, :string, default: nil
    field :accept_terms, :boolean, virtual: true
    field :todays_points, :integer, virtual: true
    field :referred_by_id, :id, default: nil
    field :push_notifications, :boolean, default: true

    # API related
    field :total_points, :decimal, virtual: true, default: Decimal.new(0)
    field :total_points_today, :decimal, virtual: true, default: Decimal.new(0)
    field :total_points_this_week, :decimal, virtual: true, default: Decimal.new(0)
    field :total_points_this_month, :decimal, virtual: true, default: Decimal.new(0)
    field :total_rewards, :integer, virtual: true, default: 0
    field :total_kilometers, :decimal, virtual: true, default: Decimal.new(0)
    field :total_kilometers_today, :decimal, virtual: true, default: Decimal.new(0)
    field :total_kilometers_this_week, :decimal, virtual: true, default: Decimal.new(0)
    field :total_kilometers_this_month, :decimal, virtual: true, default: Decimal.new(0)
    field :distance, :decimal, virtual: true, default: Decimal.new(0)

    field :offer_challenges_map, :map,
      virtual: true,
      default: %{live: [], expired: [], completed: [], total: 0}

    field :future_redeems, {:array, :map}, virtual: true, default: []
    field :past_redeems, {:array, :map}, virtual: true, default: []
    field :points_history, {:array, :map}, virtual: true, default: []
    field :total_challenges, :integer, virtual: true, default: 0
    field :position_on_leaderboard, :integer, virtual: true, default: 0
    field :friend_referrals, :integer, virtual: true
    field :chat_muted, :boolean, virtual: true
    field :marketing_email_permission, :boolean, virtual: true, default: false
    field :is_friend, :boolean, default: false, virtual: true

    field :friend_status, Ecto.Enum,
      values: [:accepted, :pending, :stranger],
      default: :stranger,
      virtual: true

    # user login info
    field :last_login_datetime, :utc_datetime

    # associations
    has_one :credential, Credential, on_replace: :update
    has_one :strava, Strava
    has_one :setting, Setting, on_replace: :update
    has_many :ngos, NGO
    has_many :ngo_chals, NGOChal
    has_many :donations, Donation
    has_many :str_customers, StrCustomer
    has_many :subscribed_email_categories, OmegaBravera.Notifications.UserEmailCategories
    has_many :offer_challenges, OfferChallenge
    has_many :activities, OmegaBravera.Activity.ActivityAccumulator
    has_many :devices, OmegaBravera.Devices.Device
    has_many :offer_redeems, OmegaBravera.Offers.OfferRedeem
    belongs_to :location, OmegaBravera.Locations.Location
    has_many :memberships, OmegaBravera.Groups.Member
    has_many :groups, through: [:memberships, :partner]

    has_many :private_chat_messages, PrivateChatMessage,
      foreign_key: :from_user_id,
      references: :id

    many_to_many :teams, Team, join_through: "team_members"

    many_to_many :offer_teams, OfferChallengeTeam,
      join_through: "offer_team_members",
      join_keys: [user_id: :id, team_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs, allowed_attrs \\ @allowed_attributes) do
    user
    |> cast(attrs, allowed_attrs)
    |> put_username()
    |> validate_required(@required_attributes)
    |> EctoCommons.EmailValidator.validate_email(:email)
    |> validate_length(:email, max: 254)
    |> lowercase_email()
    |> unique_constraint(:email)
    |> add_email_activation_token()
    |> validate_inclusion(:sync_type, Ecto.Enum.values(__MODULE__, :sync_type))
    |> cast_assoc(:setting, with: &Setting.changeset/2, required: false)
    |> cast_assoc(:credential, with: &Credential.optional_changeset/2, required: false)
  end

  def create_credential_user_changeset(user, attrs \\ %{credential: %{}}, referral \\ nil) do
    user
    |> changeset(attrs)
    |> validate_required([:email, :accept_terms])
    |> validate_acceptance(:accept_terms)
    |> add_referred_by(referral)
    |> cast_assoc(:credential, with: &Credential.changeset/2, required: true)
  end

  def delete_profile_picture_changeset(user) do
    user
    |> cast(%{}, [])
    |> put_change(:profile_picture, nil)
  end

  def update_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> email_changed(user)
  end

  def push_notifications_changeset(user, attrs) do
    user
    |> cast(attrs, [:push_notifications])
    |> validate_required([:push_notifications])
  end

  def admin_update_changeset(user, attrs) do
    user
    |> changeset(attrs, @allowed_attributes ++ [:daily_points_limit])
  end

  def gdpr_delete_changeset(user) do
    user
    |> delete_profile_picture_changeset()
    |> change(%{
      firstname: nil,
      lastname: nil,
      email: nil,
      location_id: nil,
      username: "deleted"
    })
  end

  def email_changed(%Ecto.Changeset{} = changeset, %__MODULE__{} = user) do
    new_email = get_field(changeset, :email)

    cond do
      new_email != user.email ->
        changeset
        |> put_change(:email_verified, false)
        |> put_change(:email_activation_token, gen_user_activate_email_token())

      true ->
        changeset
    end
  end

  def update_profile_picture_changeset(user, attrs) do
    user
    |> cast(attrs, [:profile_picture])
  end

  def update_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:new_email])
    |> validate_required([:new_email])
    |> EctoCommons.EmailValidator.validate_email(:new_email)
    |> new_email_changed()
  end

  def confirm_update_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:new_email_verification_code])
    |> validate_required([:new_email_verification_code])
    |> change_new_email(user)
  end

  def verify_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email_activation_token, :email_verified])
  end

  def new_email_changed(%Ecto.Changeset{} = changeset) do
    case changeset do
      %{valid?: true, changes: %{new_email: _email}} ->
        put_change(changeset, :new_email_verification_code, gen_user_activate_email_token())

      _ ->
        changeset
    end
  end

  def change_new_email(%Ecto.Changeset{} = changeset, %__MODULE__{} = user) do
    input_code = get_field(changeset, :new_email_verification_code)

    cond do
      input_code == user.new_email_verification_code ->
        changeset
        |> put_change(:email, get_field(changeset, :new_email))
        |> put_change(:new_email_verification_code, nil)
        |> put_change(:new_email, nil)

      true ->
        add_error(changeset, :new_email_verification_code, "The verification code is incorrect.")
    end
  end

  def add_referred_by(changeset, referral) when is_nil(referral), do: changeset

  def add_referred_by(changeset, referral) when not is_nil(referral),
    do: put_change(changeset, :referred_by_id, referral.user_id)

  def full_name(%__MODULE__{firstname: first, lastname: last}), do: "#{first} #{last}"

  defp lowercase_email(changeset) do
    case get_change(changeset, :email) do
      nil ->
        changeset

      email ->
        put_change(changeset, :email, String.downcase(email))
    end
  end

  defp put_username(changeset) do
    case get_field(changeset, :username) do
      nil ->
        put_change(
          changeset,
          :username,
          "#{get_field(changeset, :firstname)} #{get_field(changeset, :lastname)}"
        )

      _ ->
        changeset
    end
  end
end
