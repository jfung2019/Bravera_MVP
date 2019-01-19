defmodule OmegaBravera.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.{Credential, Setting}
  alias OmegaBravera.Trackers.Strava
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Challenges.{NGOChal, Team}
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Stripe.StrCustomer

  @required_attributes [:firstname, :lastname]
  @allowed_attributes [:email, :firstname, :lastname, :additional_info, :email_verified]

  schema "users" do
    field(:email, :string)
    field(:email_verified, :boolean, default: false)
    field(:email_activation_token, :string)
    field(:firstname, :string)
    field(:lastname, :string)
    field(:additional_info, :map, default: %{})

    # associations
    has_one(:credential, Credential)
    has_one(:strava, Strava)
    has_one(:setting, Setting)
    has_many(:ngos, NGO)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)
    has_many(:str_customers, StrCustomer)
    many_to_many(:teams, Team, join_through: "team_members")

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
  end

  def add_email_activation_token(%Ecto.Changeset{} = changeset) do
    email_activation_token = get_field(changeset, :email_activation_token)

    case email_activation_token do
      nil ->
        changeset
        |> Ecto.Changeset.change(%{
          email_activation_token: gen_token()
        })
      _ ->
        changeset
    end
  end

  defp gen_token(length \\ 32),
    do: :crypto.strong_rand_bytes(length)|> Base.url_encode64 |> binary_part(0, length)

  def full_name(%__MODULE__{firstname: first, lastname: last}), do: "#{first} #{last}"
  def email_activation_link(%__MODULE__{} = user),
    do: "#{Application.get_env(:omega_bravera, :app_base_url)}/user/account/activate/#{user.email_activation_token}"

end
