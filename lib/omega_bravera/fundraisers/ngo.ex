defmodule OmegaBravera.Fundraisers.NGO do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation

  @derive {Phoenix.Param, key: :slug}
  schema "ngos" do
    field(:desc, :string)
    field(:logo, :string)
    field(:image, :string)
    field(:name, :string)
    field(:slug, :string)
    # Per NGO Google Analytics ID
    field(:ga_id, :string)
    field(:url, :string)
    field(:full_desc, :string)
    field(:challenge_desc, :string)
    field(:currency, :string, default: "hkd")
    field(:minimum_donation, :integer, default: 0)
    field(:fundraising_goal, :integer, default: 0)
    field(:additional_members, :integer, default: 0)
    field(:pre_registration_start_date, :utc_datetime)
    field(:launch_date, :utc_datetime)
    field(:open_registration, :boolean, default: true)
    field(:hidden, :boolean, default: false)
    field(:hide_donor_pays_fees, :boolean, default: true)

    field(:active_challenges, :integer, default: 0, virtual: true)
    field(:utc_launch_date, :utc_datetime, virtual: true)
    field(:total_pledged, :decimal, default: 0, virtual: true)
    field(:total_secured, :decimal, default: 0, virtual: true)
    field(:num_of_challenges, :decimal, default: 0, virtual: true)
    field(:total_distance_covered, :decimal, default: 0, virtual: true)
    field(:total_calories, :decimal, default: 0, virtual: true)

    field(:activities, {:array, :string}, default: activity_options())
    field(:distances, {:array, :integer}, default: distance_options())
    field(:durations, {:array, :integer}, default: duration_options())
    field(:challenge_types, {:array, :string}, default: challenge_type_options())

    belongs_to(:user, User)
    has_many(:ngo_chals, NGOChal)
    has_many(:donations, Donation)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :name,
    :desc,
    :slug,
    :ga_id,
    :url,
    :full_desc,
    :challenge_desc,
    :user_id,
    :currency,
    :activities,
    :distances,
    :durations,
    :challenge_types,
    :minimum_donation,
    :fundraising_goal,
    :additional_members,
    :pre_registration_start_date,
    :launch_date,
    :open_registration,
    :hidden,
    :hide_donor_pays_fees
  ]
  @required_attributes [
    :name,
    :minimum_donation,
    :url,
    :fundraising_goal,
    :hide_donor_pays_fees,
    :user_id
  ]

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> generate_slug()
    |> validate_number(:minimum_donation, greater_than_or_equal_to: 0)
    |> validate_number(:fundraising_goal, greater_than_or_equal_to: 0)
    |> validate_inclusion(:currency, currency_options())
    |> validate_subset(:activities, activity_options())
    |> validate_subset(:distances, distance_options())
    |> validate_subset(:durations, duration_options())
    |> validate_subset(:challenge_types, challenge_type_options())
    |> validate_format(:url, ~r/^(https|http):\/\/\w+/)
    |> validate_open_registration()
    |> validate_pre_registration_start_date()
    |> validate_launch_date()
    |> validate_required(:slug)
    |> unique_constraint(:slug)
    |> upload_image(attrs)
    |> upload_logo(attrs)
  end

  def update_changeset(ngo, attrs) do
    ngo
    |> changeset(attrs)
    |> validate_pre_registration_start_date_modification(ngo)
    |> validate_no_active_challenges(ngo)
  end

  defp upload_image(%Ecto.Changeset{} = changeset, %{"image" => image_params}) do
    image_path = get_field(changeset, :image)

    file_uuid = UUID.uuid4(:hex)
    unique_filename = "#{file_uuid}-#{Path.extname(image_params.filename)}"
    bucket_name = Application.get_env(:omega_bravera, :images_bucket_name)

    if not is_nil(image_path) and image_path =~ "amazonaws" do
      filepath = URI.parse(image_path).path

      bucket_name
      |> ExAws.S3.delete_object(filepath)
      |> ExAws.request()
    end

    image_params.path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket_name, "ngo_images/#{unique_filename}", acl: :public_read)
    |> ExAws.request()

    changeset
    |> change(image: "https://#{bucket_name}.s3.amazonaws.com/ngo_images/#{unique_filename}")
  end

  defp upload_image(%Ecto.Changeset{} = changeset, _), do: changeset

  defp upload_logo(%Ecto.Changeset{} = changeset, %{"logo" => logo_params}) do
    logo_path = get_field(changeset, :logo)

    file_uuid = UUID.uuid4(:hex)
    logo_filename = logo_params.filename
    unique_filename = "#{file_uuid}-#{Path.extname(logo_params.filename)}"
    bucket_name = Application.get_env(:omega_bravera, :images_bucket_name)


    if not is_nil(logo_path) and logo_path =~ "amazonaws" do
      filepath = URI.parse(logo_path).path

      bucket_name
      |> ExAws.S3.delete_object(filepath)
      |> ExAws.request()
    end

    logo_params.path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket_name, "ngo_logos/#{unique_filename}", acl: :public_read)
    |> ExAws.request()

    changeset
    |> change(logo: "https://#{bucket_name}.s3.amazonaws.com/ngo_logos/#{unique_filename}")
  end

  defp upload_logo(%Ecto.Changeset{} = changeset, _), do: changeset

  def generate_slug(%Ecto.Changeset{} = changeset) do
    slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)

    cond do
      not is_nil(slug) ->
        change(changeset, slug: slug)

      is_nil(slug) and not is_nil(name) ->
        change(changeset, slug: Slug.slugify(name))

      true ->
        changeset
    end
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
          changeset,
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
end
