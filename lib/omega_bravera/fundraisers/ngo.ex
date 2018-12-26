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
    :open_registration
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
    |> add_utc_dates(ngo)
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

  defp add_utc_dates(%Ecto.Changeset{valid?: true} = changeset, %__MODULE__{} = ngo) do
    {new_utc_pre_registration_start_date, new_utc_launch_date} = switch_dates_to_utc(changeset)

    cond do
      is_nil(new_utc_pre_registration_start_date) or is_nil(new_utc_launch_date) ->
        changeset

      # Updating shouldn't include date changes if new and old values are equal and not nil.
      ( not is_nil(ngo.pre_registration_start_date) and not is_nil(ngo.launch_date) ) and
      Timex.equal?(to_datetime(ngo.pre_registration_start_date), new_utc_pre_registration_start_date) and
      Timex.equal?(to_datetime(ngo.launch_date), new_utc_launch_date) ->
        changeset
        |> delete_change(:pre_registration_start_date)
        |> delete_change(:launch_date)

      true ->
        changeset
        |> change(%{
          pre_registration_start_date: new_utc_pre_registration_start_date,
          launch_date: new_utc_launch_date
        })
    end
  end
  defp add_utc_dates(%Ecto.Changeset{} = changeset, _), do: changeset


  defp validate_pre_registration_start_date(%Ecto.Changeset{valid?: true, changes: %{pre_registration_start_date: pre_registration_start_date, launch_date: launch_date}} = changeset) do
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


  defp validate_open_registration(%Ecto.Changeset{valid?: true, changes: %{pre_registration_start_date: pre_registration_start_date, launch_date: launch_date}} = changeset) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and (is_nil(pre_registration_start_date) or is_nil(launch_date)) do
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

  defp validate_pre_registration_start_date_modification(%Ecto.Changeset{valid?: true, changes: %{pre_registration_start_date: pre_registration_start_date}} = changeset, %__MODULE__{} = ngo) do
    open_registration = get_field(changeset, :open_registration)

    case is_nil(ngo.pre_registration_start_date) do
      false ->
        case open_registration == false and
          Timex.after?(pre_registration_start_date, Timex.now())
        do
          true ->
            add_error(
              changeset_to_hk_date(changeset),
              :pre_registration_start_date,
              "Pre registration date cannot be modified because it has been reached."
            )

          _ ->
            changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_pre_registration_start_date_modification(%Ecto.Changeset{} = changeset,_ngo), do: changeset

  defp validate_no_active_challenges(
    %Ecto.Changeset{
      valid?: true,
      changes: %{open_registration: _}} = changeset,
    %__MODULE__{active_challenges: chals}) when chals > 0 do
      add_error(
        changeset_to_hk_date(changeset),
        :open_registration,
        "Cannot close/open registration due to the presence of active challenges."
      )
  end

  defp validate_no_active_challenges(changeset, _ngo), do: changeset

  defp validate_launch_date(%Ecto.Changeset{valid?: true, changes: %{launch_date: launch_date}} = changeset) do
    open_registration = get_field(changeset, :open_registration)
    case open_registration == false and Timex.before?(launch_date, Timex.now()) do
      true ->
        add_error(changeset_to_hk_date(changeset), :launch_date, "Launch date cannot be less than today's date.")

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
      |> DateTime.to_naive

    pre_registration_start_date =
      pre_registration_start_date
      |> Timex.to_datetime("Asia/Hong_Kong")
      |> DateTime.to_naive

    changeset
    |> change(%{
      pre_registration_start_date: pre_registration_start_date,
      launch_date: launch_date
    })
  end
  defp changeset_to_hk_date(%Ecto.Changeset{} = changeset), do: changeset

  defp switch_dates_to_utc(%Ecto.Changeset{
    data: %{
      launch_date: {:error, :invalid_date},
      pre_registration_start_date: {:error, :invalid_date}
    }
  }), do: {nil, nil}

  defp switch_dates_to_utc(%Ecto.Changeset{} = changeset) do
    pre_registration_start_date = get_field(changeset, :pre_registration_start_date)
    launch_date = get_field(changeset, :launch_date)

    case is_nil(pre_registration_start_date) and is_nil(launch_date) do
      true ->
        {nil, nil}
      _ ->
        {
          pre_registration_start_date
          |> to_datetime(),

          launch_date
          |> to_datetime()
        }
    end
  end

  defp to_datetime(datetime) do
    case is_tuple(datetime) do
      true ->
        datetime |> date_tuple_to_datetime()
      false ->
        datetime |> from_hk_to_utc()
    end
  end

  defp date_tuple_to_datetime({{year, month, day}, {hour, minutes, seconds, microseconds}}) do
    Timex.to_datetime({{year, month, day}, {hour, minutes, seconds, microseconds}}, "Asia/Hong_Kong")
    |> Timex.to_datetime("Etc/UTC")
  end
  defp date_tuple_to_datetime(nil), do: nil

  defp from_hk_to_utc(%DateTime{} = datetime) do
    datetime
    |> Timex.to_datetime()
    |> DateTime.to_naive
    |> Timex.to_datetime("Asia/Hong_Kong")
    |> Timex.to_datetime("Etc/UTC")
  end

  defp valid_currencies, do: Map.values(currency_options())

  def activity_options, do: @available_activities

  def distance_options, do: @available_distances

  def duration_options, do: @available_durations

  def challenge_type_options, do: @available_challenge_type_options
end

defimpl Phoenix.Param, for: OmegaBravera.Fundraisers.NGO do
  def to_param(%{slug: slug}), do: slug
end
