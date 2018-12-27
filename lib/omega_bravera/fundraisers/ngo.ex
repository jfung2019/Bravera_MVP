defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation

  @available_activities ["Run", "Cycle", "Walk", "Hike"]
  @available_distances [50, 75, 100, 150, 250, 300, 400, 500]
  @available_durations [20, 24, 30, 40, 50, 60, 70, 80]

  # TODO: put NGO Challenge and NGO together in same module
  @per_km "PER_KM"
  @per_milestone "PER_MILESTONE"

  @available_challenge_type_options [
    [key: "Per Goal", value: @per_milestone],
    [key: "Per KM", value: @per_km]
  ]

  @available_challenge_types [@per_milestone, @per_km]

  @derive {Phoenix.Param, key: :slug}
  schema "ngos" do
    field(:desc, :string)
    field(:logo, :string)
    field(:image, :string)
    field(:name, :string)
    field(:slug, :string)
    field(:url, :string)
    field(:full_desc, :string)
    field(:currency, :string, default: "hkd")
    field(:minimum_donation, :integer, default: 0)
    field(:pre_registration_start_date, :utc_datetime)
    field(:launch_date, :utc_datetime)
    field(:open_registration, :boolean, default: true)
    field(:hidden, :boolean, default: false)
    field(:active_challenges, :integer, default: 0, virtual: true)
    field(:utc_launch_date, :utc_datetime, virtual: true)
    field(:activities, {:array, :string}, default: @available_activities)
    field(:distances, {:array, :integer}, default: @available_distances)
    field(:durations, {:array, :integer}, default: @available_durations)
    field(:challenge_types, {:array, :string}, default: @available_challenge_types)
    belongs_to(:user, User)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :name,
    :desc,
    :logo,
    :image,
    :slug,
    :url,
    :full_desc,
    :user_id,
    :currency,
    :activities,
    :distances,
    :durations,
    :challenge_types,
    :minimum_donation,
    :pre_registration_start_date,
    :launch_date,
    :open_registration,
    :hidden
  ]
  @required_attributes [:name, :slug, :minimum_donation, :url, :logo, :image]

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_number(:minimum_donation, greater_than_or_equal_to: 0)
    |> validate_inclusion(:currency, valid_currencies())
    |> validate_subset(:activities, @available_activities)
    |> validate_subset(:distances, @available_distances)
    |> validate_subset(:durations, @available_durations)
    |> validate_subset(:challenge_types, @available_challenge_types)
    |> validate_format(:url, ~r/^(https|http):\/\/\w+/)
    |> validate_open_registration()
    |> validate_pre_registration_start_date()
    |> validate_launch_date()
    |> unique_constraint(:slug)
  end

  def update_changeset(ngo, attrs) do
    ngo
    |> changeset(attrs)
    |> validate_pre_registration_start_date_modification(ngo)
    |> validate_no_active_challenges(ngo)
  end

  def currency_options do
    %{
      "Hong Kong Dollar (HKD)" => "hkd",
      "South Korean Won (KRW)" => "krw",
      "Singapore Dollar (SGD)" => "sgd",
      "Malaysian Ringgit (MYR)" => "myr",
      "United States Dollar (USD)" => "usd",
      "British Pound (GBP)" => "gbp"
    }
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
          changeset_to_hk_date(changeset),
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
          changeset_to_hk_date(changeset),
          :open_registration,
          "Cannot create non-closed registration NGO without registration dates."
        )

      _ ->
        changeset
    end
  end

  defp validate_open_registration(%Ecto.Changeset{} = changeset), do: changeset

  defp validate_pre_registration_start_date_modification(
         %Ecto.Changeset{
           valid?: true,
           changes: %{pre_registration_start_date: pre_registration_start_date}
         } = changeset,
         %__MODULE__{} = _ngo
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

  defp validate_pre_registration_start_date_modification(%Ecto.Changeset{} = changeset, _ngo),
    do: changeset

  defp validate_no_active_challenges(
         %Ecto.Changeset{valid?: true, changes: %{open_registration: _}} = changeset,
         %__MODULE__{active_challenges: chals}
       )
       when chals > 0 do
    add_error(
      changeset_to_hk_date(changeset),
      :open_registration,
      "Cannot close/open registration due to the presence of active challenges."
    )
  end

  defp validate_no_active_challenges(changeset, _ngo), do: changeset

  defp validate_launch_date(
         %Ecto.Changeset{valid?: true, changes: %{launch_date: launch_date}} = changeset
       ) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and Timex.before?(launch_date, Timex.now()) do
      true ->
        add_error(
          changeset_to_hk_date(changeset),
          :launch_date,
          "Launch date cannot be less than today's date."
        )

      _ ->
        changeset
    end
  end

  defp validate_launch_date(%Ecto.Changeset{} = changeset), do: changeset

  defp changeset_to_hk_date(
         %Ecto.Changeset{
           changes: %{
             launch_date: launch_date,
             pre_registration_start_date: pre_registration_start_date
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

    changeset
    |> change(%{
      pre_registration_start_date: pre_registration_start_date,
      launch_date: launch_date
    })
  end

  defp changeset_to_hk_date(%Ecto.Changeset{} = changeset), do: changeset

  defp valid_currencies, do: Map.values(currency_options())

  def activity_options, do: @available_activities

  def distance_options, do: @available_distances

  def duration_options, do: @available_durations

  def challenge_type_options, do: @available_challenge_type_options
end

defimpl Phoenix.Param, for: OmegaBravera.Fundraisers.NGO do
  def to_param(%{slug: slug}), do: slug
end
