defmodule OmegaBravera.Offers.Offer do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.Offers.{OfferChallenge, OfferReward, OfferVendor, OfferRedeem}

  @derive {Phoenix.Param, key: :slug}
  schema "offers" do
    field(:currency, :string, default: "hkd")
    field(:desc, :string)
    field(:full_desc, :string)
    field(:ga_id, :string)
    field(:image, :string)
    field(:logo, :string)
    field(:name, :string)
    field(:offer_challenge_desc, :string)
    field(:offer_percent, :float)
    field(:hidden, :boolean, default: false)

    field(:pre_registration_start_date, :utc_datetime)
    # When true, pre_registration_start_date, will be ignored.
    # When false, challenges will be in pre_registration mode
    field(:open_registration, :boolean, default: true)

    # Does not affect anything... as requested by Alyn in 1119.
    field(:start_date, :utc_datetime)
    field(:end_date, :utc_datetime)

    # NO LOGIC IMPLEMENTED YET.
    # When true, all challenges will ignore the end_date.
    field(:always, :boolean, default: false)

    field(:payment_enabled, :boolean, default: false)

    # When more than 0, all challenges will have a single team.
    field(:additional_members, :integer, default: 0)

    field(:slug, :string)
    field(:toc, :string)
    field(:url, :string)
    field(:time_limit, :integer, default: 0)

    field(:active_offer_challenges, :integer, default: 0, virtual: true)
    field(:num_of_challenges, :decimal, default: 0, virtual: true)
    field(:total_distance_covered, :decimal, default: 0, virtual: true)
    field(:total_calories, :decimal, default: 0, virtual: true)
    field(:unique_participants, :integer, default: 0, virtual: true)

    field(:activities, {:array, :string})
    field(:distances, {:array, :integer})
    field(:offer_challenge_types, {:array, :string})

    belongs_to(:vendor, OfferVendor)
    has_many(:offer_challenges, OfferChallenge)
    has_many(:offer_rewards, OfferReward)
    has_many(:offer_redeems, OfferRedeem)

    timestamps(type: :utc_datetime)
  end

  @allowed_atributes [
    :name,
    :slug,
    :ga_id,
    :pre_registration_start_date,
    :open_registration,
    :start_date,
    :end_date,
    :always,
    :hidden,
    :desc,
    :full_desc,
    :toc,
    :offer_challenge_desc,
    :offer_percent,
    :url,
    :currency,
    :additional_members,
    :offer_challenge_types,
    :distances,
    :activities,
    :vendor_id,
    :time_limit
  ]
  @required_attributes [
    :name,
    :url,
    :offer_challenge_types,
    :distances,
    :activities,
    :start_date,
    :end_date,
    :toc,
    :vendor_id
  ]

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, @allowed_atributes)
    |> validate_required(@required_attributes)
    |> validate_length(:name, max: 77)
    |> generate_slug()
    |> validate_inclusion(:currency, currency_options())
    |> validate_subset(:activities, activity_options())
    |> validate_subset(:distances, distance_options())
    |> validate_subset(:offer_challenge_types, challenge_type_options())
    |> validate_format(:url, ~r/^(https|http):\/\/\w+/)
    |> validate_open_registration()
    |> validate_pre_registration_start_date()
    |> validate_required(:slug)
    |> unique_constraint(:slug)
    |> upload_image(attrs)
    |> upload_logo(attrs)
  end

  def update_changeset(offer, attrs) do
    offer
    |> changeset(attrs)
    |> validate_pre_registration_start_date_modification(offer)
    |> validate_no_active_challenges(offer)
  end

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
    |> ExAws.S3.upload(bucket_name, "offer_images/#{unique_filename}", acl: :public_read)
    |> ExAws.request()

    changeset
    |> change(image: "https://#{bucket_name}.s3.amazonaws.com/offer_images/#{unique_filename}")
  end

  defp upload_image(%Ecto.Changeset{} = changeset, _), do: changeset

  defp upload_logo(%Ecto.Changeset{} = changeset, %{"logo" => logo_params}) do
    logo_path = get_field(changeset, :logo)

    file_uuid = UUID.uuid4(:hex)
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
    |> ExAws.S3.upload(bucket_name, "offer_logos/#{unique_filename}", acl: :public_read)
    |> ExAws.request()

    changeset
    |> change(logo: "https://#{bucket_name}.s3.amazonaws.com/offer_logos/#{unique_filename}")
  end

  defp upload_logo(%Ecto.Changeset{} = changeset, _), do: changeset

  defp validate_pre_registration_start_date(
         %Ecto.Changeset{
           valid?: true,
           changes: %{
             pre_registration_start_date: pre_registration_start_date,
             start_date: start_date
           }
         } = changeset
       ) do
    open_registration = get_field(changeset, :open_registration)

    case open_registration == false and
           (Timex.after?(pre_registration_start_date, start_date) or
              Timex.equal?(pre_registration_start_date, start_date)) do
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
    start_date = get_field(changeset, :start_date)

    case open_registration == false and
           (is_nil(pre_registration_start_date) or is_nil(start_date)) do
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

  # defp validate_launch_date(
  #        %Ecto.Changeset{valid?: true, changes: %{launch_date: launch_date}} = changeset
  #      ) do
  #   open_registration = get_field(changeset, :open_registration)

  #   case open_registration == false and Timex.before?(launch_date, Timex.now()) do
  #     true ->
  #       add_error(
  #         changeset,
  #         :launch_date,
  #         "Launch date cannot be less than today's date."
  #       )

  #     _ ->
  #       changeset
  #   end
  # end

  # defp validate_launch_date(%Ecto.Changeset{} = changeset), do: changeset

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

  defp validate_no_active_challenges(changeset, _offer), do: changeset

  defp changeset_to_hk_date(
         %Ecto.Changeset{
           changes: %{
             pre_registration_start_date: pre_registration_start_date,
             start_date: start_date,
             end_date: end_date
           }
         } = changeset
       ) do
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
      start_date: start_date,
      end_date: end_date
    })
  end

  defp changeset_to_hk_date(%Ecto.Changeset{} = changeset), do: changeset
end
