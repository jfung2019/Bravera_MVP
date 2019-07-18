defmodule OmegaBravera.Trackers.Strava do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Accounts.User

  schema "stravas" do
    field(:athlete_id, :integer)
    field(:email, :string)
    field(:firstname, :string)
    field(:lastname, :string)
    field(:token, :string)
    field(:refresh_token, :string)
    field(:token_expires_at, :utc_datetime)
    field(:strava_profile_picture, :string, default: nil)
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @required_attributes [:athlete_id, :firstname, :lastname, :token]
  @allowed_attributes [:strava_profile_picture | @required_attributes]

  @doc false
  def changeset(strava, attrs) do
    strava
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> unique_constraint(:athlete_id)
  end
end
