defmodule OmegaBravera.Offers.OfferRedeem do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.{Offer, OfferChallenge, OfferReward, OfferVendor}
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Repo

  schema "offer_redeems" do
    field(:token, :string)
    # Can be pending or redeemed
    field(:status, :string, default: "pending")

    belongs_to(:offer_reward, OfferReward)
    belongs_to(:offer_challenge, OfferChallenge)
    belongs_to(:offer, Offer)
    belongs_to(:user, User)
    belongs_to(:vendor, OfferVendor)

    timestamps(type: :utc_datetime)
  end

  # Should remove vendor_id?, token, and status.
  @allowed_atributes [:offer_reward_id, :vendor_id, :token, :status]

  @doc false
  def changeset(%__MODULE__{} = offer_redeems, attrs \\ %{}) do
    offer_redeems
    |> cast(attrs, @allowed_atributes)
  end

  def offer_challenge_assoc_changeset(
        %__MODULE__{} = offer_redeems,
        %Offer{id: offer_id, vendor_id: vendor_id},
        %User{id: user_id},
        attrs \\ %{}
      ) do
    offer_redeems
    |> cast(attrs, @allowed_atributes)
    |> put_change(:offer_id, offer_id)
    |> put_change(:user_id, user_id)
    |> put_change(:vendor_id, vendor_id)
    |> put_change(:token, gen_token())
    |> validate_required([:offer_id, :user_id, :vendor_id, :token])
  end

  def create_changeset(offer_redeems, offer_challenge, vendor, attrs \\ %{}, team_user \\ %User{})

  def create_changeset(_, _, vendor, attrs, _) when is_nil(vendor) == true do
    %__MODULE__{}
    |> changeset(attrs)
    |> add_error(:vendor_id, "Your Vendor ID seems to be incorrect.")
  end

  def create_changeset(
        %__MODULE__{} = offer_redeems,
        %OfferChallenge{offer_id: offer_id, user_id: challenge_owner_id} = offer_challenge,
        %OfferVendor{} = vendor,
        attrs,
        team_user
      ) do
    changeset(offer_redeems, attrs)
    |> put_change(:vendor_id, vendor.id)
    |> put_change(:offer_challenge_id, offer_challenge.id)
    |> put_change(:offer_id, offer_id)
    |> put_change(:token, gen_token())
    |> validate_required([:vendor_id, :token])
    |> add_team_id(offer_challenge)
    |> add_user_id(challenge_owner_id, team_user)
    |> unique_constraint(:id,
      name: :offer_redeems_offer_challenge_id_user_id_index,
      message: "Already created a redeem"
    )
  end

  # Used only in the migration. Should be disgraded after we migrate prod db.
  def update_changeset(%__MODULE__{} = offer_redeem, attrs \\ %{}) do
    offer_redeem
    |> cast(attrs, @allowed_atributes)
  end

  def redeem_reward_changeset(nil, _, _) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> add_error(:id, "Invalid redeem link/token.")
  end

  def redeem_reward_changeset(_, nil, _) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> add_error(:id, "Offer Challenge not found in database.")
  end

  def redeem_reward_changeset(_, _, nil, _, _) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> add_error(:id, "Offer not found in database.")
  end

  def redeem_reward_changeset(_, _, _, nil, _) do
    %__MODULE__{}
    |> cast(%{}, [])
    |> add_error(:id, "Vendor not found in database.")
  end

  def redeem_reward_changeset(
        %__MODULE__{} = offer_redeem,
        %OfferChallenge{id: challenge_id},
        %Offer{vendor_id: offer_vendor_id},
        %OfferVendor{id: input_vendor_id},
        attrs
      ) do
    offer_redeem
    |> cast(attrs, [:offer_reward_id])
    |> validate_required([:offer_reward_id])
    |> validate_number(:offer_challenge_id,
      equal_to: challenge_id,
      message: "Offer Challenge has no such redeem token."
    )
    |> put_change(:status, "redeemed")
    |> validate_vendor(offer_vendor_id, input_vendor_id)
    |> validate_previously_redeemed(offer_redeem)
  end

  defp add_user_id(%Ecto.Changeset{} = changeset, _, %User{id: team_user_id})
       when not is_nil(team_user_id),
       do: put_change(changeset, :user_id, team_user_id)

  defp add_user_id(%Ecto.Changeset{} = changeset, challenge_owner_id, %User{id: team_user_id})
       when is_nil(team_user_id),
       do: put_change(changeset, :user_id, challenge_owner_id)

  defp add_user_id(%Ecto.Changeset{} = changeset, challenge_owner_id, nil),
    do: put_change(changeset, :user_id, challenge_owner_id)

  defp validate_vendor(%Ecto.Changeset{} = changeset, offer_vendor_id, input_vendor_id) do
    if offer_vendor_id == input_vendor_id do
      changeset
    else
      changeset
      |> add_error(:vendor_id, "Your Vendor ID seems to be incorrect.")
    end
  end

  defp add_team_id(%Ecto.Changeset{} = changeset, %OfferChallenge{has_team: false}), do: changeset

  defp add_team_id(
         %Ecto.Changeset{} = changeset,
         %OfferChallenge{has_team: true} = offer_challenge
       ) do
    offer_challenge = Repo.preload(offer_challenge, [:team])

    put_change(changeset, :team_id, offer_challenge.team.id)
  end

  defp validate_previously_redeemed(
         %Ecto.Changeset{} = changeset,
         %__MODULE__{status: status}
       )
       when status == "redeemed" do
    add_error(changeset, :status, "Reward previously redeemed.")
  end

  defp validate_previously_redeemed(%Ecto.Changeset{} = changeset, _), do: changeset

  defp gen_token(length \\ 10),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
