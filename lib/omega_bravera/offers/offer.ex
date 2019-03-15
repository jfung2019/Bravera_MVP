defmodule OmegaBravera.Offers.Offer do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{Accounts.User, Offers.OfferChallenge}

  @derive {Phoenix.Param, key: :slug}
  schema "offers" do
    field(:currency, :string, default: "hkd")
    field(:desc, :string)
    field(:full_desc, :string)
    field(:ga_id, :string)
    field(:image, :string)
    field(:launch_date, :utc_datetime)
    field(:logo, :string)
    field(:name, :string)
    field(:offer_challenge_desc, :string)
    field(:offer_percent, :float)
    field(:hidden, :boolean, default: false)
    field(:open_registration, :boolean, default: true)
    field(:pre_registration_start_date, :utc_datetime)
    field(:start_date, :utc_datetime)
    field(:end_date, :utc_datetime)
    field(:reward_value, :integer)
    field(:additional_members, :integer, default: 0)
    field(:slug, :string)
    field(:toc, :string)
    field(:url, :string)

    field(:active_offer_challenges, :integer, default: 0, virtual: true)
    field(:num_of_challenges, :decimal, default: 0, virtual: true)
    field(:total_distance_covered, :decimal, default: 0, virtual: true)
    field(:total_calories, :decimal, default: 0, virtual: true)

    field(:activities, {:array, :string})
    field(:distances, {:array, :integer})
    field(:durations, {:array, :integer})
    field(:offer_challenge_types, {:array, :string})

    belongs_to(:user, User)
    has_many(:offer_challenges, OfferChallenge)

    timestamps(type: :utc_datetime)
  end

  @allowed_atributes [
    :name,
    :slug,
    :ga_id,
    :pre_registration_start_date,
    :launch_date,
    :start_date,
    :end_date,
    :open_registration,
    :hidden,
    :desc,
    :full_desc,
    :toc,
    :offer_challenge_desc,
    :reward_value,
    :offer_percent,
    :image,
    :logo,
    :url,
    :currency,
    :additional_members,
    :offer_challenge_types,
    :distances,
    :durations,
    :activities,
    :user_id
  ]
  @required_attributes [
    :name,
    :slug,
    :url,
    :logo,
    :user_id,
    :offer_challenge_types,
    :distances,
    :durations,
    :activities,
    :start_date,
    :end_date,
    :toc
  ]

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, @allowed_atributes)
    |> validate_required(@required_attributes)
    |> validate_inclusion(:currency, currency_options())
    |> validate_subset(:activities, activity_options())
    |> validate_subset(:distances, distance_options())
    |> validate_subset(:durations, duration_options())
    |> validate_subset(:offer_challenge_types, challenge_type_options())
    |> validate_format(:url, ~r/^(https|http):\/\/\w+/)
    |> validate_open_registration()
    |> validate_pre_registration_start_date()
    |> validate_launch_date()
    |> unique_constraint(:slug)
  end

  def update_changeset(offer, attrs) do
    offer
    |> changeset(attrs)
    |> validate_pre_registration_start_date_modification(offer)
    |> validate_no_active_challenges(offer)
  end

  defp validate_pre_registration_start_date(
         %Ecto.Changeset{
           valid?: true,
           changes: %{
             pre_registration_start_date: pre_registration_start_date,
             launch_date: launch_date
           }
         } = changeset
       ) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and
           (Timex.after?(pre_registration_start_date, launch_date) or
              Timex.equal?(pre_registration_start_date, launch_date)) do
      true ->
        add_error(
          changeset,
          :pre_registration_start_date,
          "Pre-registration start date cannot be greater than or equal to the Launch date."
        )

      _ ->
        changeset
    end
  end

  defp validate_pre_registration_start_date(%Ecto.Changeset{} = changeset), do: changeset

  defp validate_open_registration(%Ecto.Changeset{valid?: true} = changeset) do
    open_registration = get_field(changeset, :open_registration)
    pre_registration_start_date = get_field(changeset, :pre_registration_start_date)
    launch_date = get_field(changeset, :launch_date)

    case open_registration == false and
           (is_nil(pre_registration_start_date) or is_nil(launch_date)) do
      true ->
        add_error(
          changeset,
          :open_registration,
          "Cannot create non-closed registration Offer without registration dates."
        )

      _ ->
        changeset
    end
  end

  defp validate_open_registration(%Ecto.Changeset{} = changeset), do: changeset

  defp validate_launch_date(
         %Ecto.Changeset{valid?: true, changes: %{launch_date: launch_date}} = changeset
       ) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and Timex.before?(launch_date, Timex.now()) do
      true ->
        add_error(
          changeset,
          :launch_date,
          "Launch date cannot be less than today's date."
        )

      _ ->
        changeset
    end
  end

  defp validate_launch_date(%Ecto.Changeset{} = changeset), do: changeset

  defp validate_pre_registration_start_date_modification(
         %Ecto.Changeset{
           valid?: true,
           changes: %{pre_registration_start_date: pre_registration_start_date}
         } = changeset,
         %__MODULE__{} = _offer
       ) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and Timex.after?(pre_registration_start_date, Timex.now()) do
      true ->
        add_error(
          changeset_to_hk_date(changeset),
          :pre_registration_start_date,
          "Pre registration date cannot be modified because it has been reached."
        )

      _ ->
        changeset
    end
  end

  defp validate_pre_registration_start_date_modification(%Ecto.Changeset{} = changeset, _offer),
    do: changeset

  defp validate_no_active_challenges(
         %Ecto.Changeset{valid?: true, changes: %{open_registration: _}} = changeset,
         %__MODULE__{active_offer_challenges: chals}
       )
       when chals > 0 do
    add_error(
      changeset_to_hk_date(changeset),
      :open_registration,
      "Cannot close/open registration due to the presence of active offer challenges."
    )
  end

  defp validate_no_active_challenges(changeset, _ngo), do: changeset

  defp changeset_to_hk_date(
         %Ecto.Changeset{
           changes: %{
             launch_date: launch_date,
             pre_registration_start_date: pre_registration_start_date,
             start_date: start_date,
             end_date: end_date
           }
         } = changeset
       ) do
    launch_date =
      launch_date
      |> Timex.to_datetime("Asia/Hong_Kong")
      |> DateTime.to_naive()

    pre_registration_start_date =
      pre_registration_start_date
      |> Timex.to_datetime("Asia/Hong_Kong")
      |> DateTime.to_naive()

    start_date =
      start_date
      |> Timex.to_datetime("Asia/Hong_Kong")
      |> DateTime.to_naive()

    end_date =
      end_date
      |> Timex.to_datetime("Asia/Hong_Kong")
      |> DateTime.to_naive()

    changeset
    |> change(%{
      pre_registration_start_date: pre_registration_start_date,
      launch_date: launch_date,
      start_date: start_date,
      end_date: end_date
    })
  end

  defp changeset_to_hk_date(%Ecto.Changeset{} = changeset), do: changeset
end
