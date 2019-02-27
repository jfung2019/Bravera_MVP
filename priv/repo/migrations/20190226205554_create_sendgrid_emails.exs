defmodule OmegaBravera.Repo.Migrations.CreateSendgridEmails do
  use Ecto.Migration

  def change do
    create table(:sendgrid_emails) do
      add :sendgrid_id, :string
      add :category_id, references(:email_categories, on_delete: :nothing)

      timestamps(type: :timestamptz)
    end

    create index(:sendgrid_emails, [:category_id])
    create unique_index(:sendgrid_emails, [:sendgrid_id])
  end
end
