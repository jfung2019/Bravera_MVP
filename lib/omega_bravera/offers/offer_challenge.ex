defmodule OmegaBravera.Offers.OfferChallenge do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{Offers.Offer, Accounts.User}

  schema "offer_challenges" do
    field(:activity_type, :string)
    field(:default_currency, :string, default: "hkd")
    field(:distance_target, :integer, default: 100)
    field(:duration, :integer)
    field(:end_date, :utc_datetime)
    field(:has_team, :boolean, default: false)
    field(:last_activity_received, :utc_datetime)
    field(:participant_notified_of_inactivity, :boolean, default: false)
    field(:slug, :string)
    field(:start_date, :utc_datetime)
    field(:status, :string, default: "active")
    field(:type, :string)

    field(:distance_covered, :decimal, default: 0, virtual: true)

    belongs_to(:user, User)
    belongs_to(:offer, Offer)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :user_id,
    :offer_id
  ]

  @required_attributes [
    :user_id,
    :offer_id
  ]

  @doc false
  def changeset(offer_challenge, attrs) do
    offer_challenge
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distance_options())
    |> validate_inclusion(:activity_type, activity_options())
    |> validate_inclusion(:default_currency, currency_options())
    |> validate_inclusion(:duration, duration_options())
    |> validate_inclusion(:type, challenge_type_options())
    |> unique_constraint(:slug)
  end

  def create_changeset(offer_challenge, offer, attrs) do
    offer_challenge
    |> changeset(attrs)
    |> add_start_and_end_dates(offer, attrs)
    |> add_status(offer)
    |> add_last_activity_received(offer)
    |> validate_required([:start_date, :end_date])
  end

  defp add_status(%Ecto.Changeset{} = changeset, %Offer{
         open_registration: open_registration,
         launch_date: launch_date
       }) do
    status =
      case open_registration == false and Timex.after?(launch_date, Timex.now()) do
        true -> "pre_registration"
        _ -> "active"
      end

    changeset
    |> change(status: status)
  end

  defp add_last_activity_received(%Ecto.Changeset{} = changeset, %Offer{launch_date: launch_date}) do
    status = get_field(changeset, :status)

    last_activity_received =
      case status do
        "pre_registration" -> launch_date
        _ -> Timex.now()
      end

    changeset
    |> change(last_activity_received: DateTime.truncate(last_activity_received, :second))
  end

  defp add_start_and_end_dates(
         %Ecto.Changeset{} = changeset,
         %Offer{} = offer,
         %{"duration" => duration_str} = attrs
       )
       when is_binary(duration_str) do
    duration =
      case Integer.parse(duration_str) do
        {duration, _} -> duration
        _ -> nil
      end

    add_start_and_end_dates(changeset, offer, Map.put(attrs, "duration", duration))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %Offer{} = offer, %{
         "duration" => duration
       })
       when is_number(duration) do
    {start_date, end_date} =
      cond do
        offer.open_registration == false and Timex.after?(offer.utc_launch_date, Timex.now()) ->
          {offer.utc_launch_date, Timex.shift(offer.utc_launch_date, days: duration)}

        true ->
          {Timex.now(), Timex.shift(Timex.now(), days: duration)}
      end

    changeset
    |> change(start_date: DateTime.truncate(start_date, :second))
    |> change(end_date: DateTime.truncate(end_date, :second))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, _, _), do: changeset
end
