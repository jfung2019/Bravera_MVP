defmodule OmegaBravera.Offers.Offer do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.Offers.{OfferChallenge, OfferReward, OfferVendor, OfferRedeem}
  alias OmegaBravera.Groups.OfferPartner

  @url_regex ~r/^(https|http):\/\/\w+/

  @derive {Phoenix.Param, key: :slug}
  schema "offers" do
    field :currency, :string, default: "hkd"
    field :desc, :string
    field :full_desc, :string
    field :ga_id, :string
    field :image, :string
    field :images, {:array, :string}, default: []
    field :logo, :string
    field :name, :string
    field :offer_challenge_desc, :string
    field :external_terms_url, :string
    field :accept_terms_text, :string, default: "I accept the waiver & release of liability"
    field :offer_percent, :float
    field :hidden, :boolean, default: true
    field :approval_status, Ecto.Enum, values: [:approved, :denied, :pending], default: :pending
    field :redemption_days, :integer
    field :offer_type, Ecto.Enum, values: [:in_store, :online], default: :in_store
    field :take_challenge, :boolean, default: true
    field :online_url, :string
    field :online_code, :string

    field :pre_registration_start_date, :utc_datetime
    # When true, pre_registration_start_date, will be ignored.
    # When false, challenges will be in pre_registration mode
    field :open_registration, :boolean, default: true

    # Does not affect anything... as requested by Alyn in 1119.
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime

    # NO LOGIC IMPLEMENTED YET.
    # When true, all challenges will ignore the end_date.
    field :always, :boolean, default: false

    field :payment_amount, :decimal, default: nil

    # When more than 0, all challenges will have a single team.
    field :additional_members, :integer, default: 0

    field :slug, :string
    field :toc, :string
    field :url, :string, default: "https://www.bravera.fit/"
    field :time_limit, :integer, default: 0
    field :form_url, :string

    field :active_offer_challenges, :integer, default: 0, virtual: true
    field :num_of_challenges, :decimal, default: 0, virtual: true
    field :total_distance_covered, :decimal, default: 0, virtual: true
    field :total_calories, :decimal, default: 0, virtual: true
    field :unique_participants, :integer, default: 0, virtual: true

    field :activities, {:array, :string}, default: ["Run"]
    field :target, :integer
    field :offer_challenge_types, {:array, :string}, default: ["PER_KM"]

    belongs_to :vendor, OfferVendor
    belongs_to :location, OmegaBravera.Locations.Location
    has_many :offer_challenges, OfferChallenge
    has_many :offer_rewards, OfferReward
    has_many :offer_redeems, OfferRedeem
    has_many :offer_partners, OfferPartner
    has_many :partners, through: [:offer_partners, :partner]
    belongs_to :organization, OmegaBravera.Accounts.Organization, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :name,
    :slug,
    :ga_id,
    :pre_registration_start_date,
    :open_registration,
    :start_date,
    :end_date,
    :always,
    :hidden,
    :live,
    :approval_status,
    :desc,
    :full_desc,
    :toc,
    :offer_challenge_desc,
    :offer_percent,
    :url,
    :currency,
    :additional_members,
    :offer_challenge_types,
    :target,
    :activities,
    :vendor_id,
    :time_limit,
    :payment_amount,
    :external_terms_url,
    :accept_terms_text,
    :location_id,
    :images,
    :redemption_days,
    :offer_type,
    :take_challenge,
    :online_url,
    :online_code,
    :form_url,
    :organization_id
  ]
  @required_attributes [
    :name,
    :url,
    :offer_challenge_types,
    :target,
    :activities,
    :start_date,
    :end_date,
    :toc,
    :take_challenge,
    :offer_type
  ]

  @doc false
  def changeset(offer, attrs) do
    offer
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_length(:name, max: 77)
    |> generate_slug()
    |> validate_inclusion(:currency, currency_options())
    |> validate_subset(:activities, activity_options())
    |> validate_subset(:offer_challenge_types, challenge_type_options())
    |> validate_inclusion(:offer_type, available_offer_types())
    |> validate_format(:url, @url_regex)
    |> validate_format(:online_url, @url_regex)
    |> validate_format(:form_url, @url_regex)
    |> validate_open_registration()
    |> validate_pre_registration_start_date()
    |> validate_required(:slug)
    |> unique_constraint(:slug)
    |> upload_logo(attrs)
    |> validate_offer_type()
    |> validate_inclusion(:approval_status, available_approval_status())
  end

  def update_changeset(offer, attrs) do
    offer
    |> changeset(attrs)
    |> validate_length(:images, min: 1)
    |> validate_pre_registration_start_date_modification(offer)
    |> validate_no_active_challenges(offer)
  end

  def org_online_offer_changeset(offer, attrs) do
    changeset(offer, attrs)
    |> validate_required([:organization_id, :online_url, :online_code, :redemption_days])
    |> put_change(:offer_type, :online)
  end

  def org_offline_offer_changeset(offer, attrs) do
    changeset(offer, attrs)
    |> validate_required([:organization_id, :vendor_id, :location_id, :redemption_days])
    |> put_change(:offer_type, :in_store)
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

  def available_offer_types, do: Ecto.Enum.values(__MODULE__, :offer_type)

  def available_approval_status, do: Ecto.Enum.values(__MODULE__, :approval_status)

  defp upload_logo(%Ecto.Changeset{} = changeset, %{"logo" => logo_params}) do
    logo_path = get_field(changeset, :logo)

    file_uuid = Ecto.UUID.generate()
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

  defp validate_offer_type(changeset) do
    type = get_field(changeset, :offer_type)

    case type do
      :online ->
        validate_required(changeset, [:online_url, :online_code])

      _ ->
        changeset
    end
  end
end
