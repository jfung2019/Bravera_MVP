defmodule OmegaBravera.Repo.Migrations.CreateOffers do
  use Ecto.Migration

  def change do
    create table(:offers) do
      add(:name, :string)
      add(:slug, :string)
      add(:ga_id, :string)
      add(:pre_registration_start_date, :utc_datetime)
      add(:launch_date, :utc_datetime)
      add(:open_registration, :boolean, default: false, null: false)
      add(:hidden, :boolean, default: false, null: false)
      add(:desc, :string)
      add(:full_desc, :text)
      add(:toc, :text)
      add(:offer_challenge_desc, :text)
      add(:reward_value, :integer)
      add(:offer_percent, :float)
      add(:image, :string)
      add(:logo, :string)
      add(:url, :string)
      add(:currency, :string, null: false, default: "hkd")
      add(:additional_members, :integer)

      add(:offer_challenge_types, {:array, :string},
        null: false,
        default: fragment("ARRAY['PER_KM', 'PER_MILESTONE']")
      )

      add(:distances, {:array, :string},
        null: false,
        default: fragment("ARRAY[50, 75, 150, 250]")
      )

      add(:durations, {:array, :integer},
        null: false,
        default: fragment("ARRAY[30, 40, 50, 60]")
      )

      add(:activities, {:array, :string},
        null: false,
        default: fragment("ARRAY['Run', 'Cycle', 'Walk', 'Hike']")
      )

      add(:user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(unique_index(:offers, [:slug]))
    create(index(:offers, [:user_id]))
  end
end
