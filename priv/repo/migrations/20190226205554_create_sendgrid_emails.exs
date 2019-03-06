defmodule OmegaBravera.Repo.Migrations.CreateSendgridEmails do
  use Ecto.Migration

  alias OmegaBravera.Emails

  def change do
    create table(:sendgrid_emails) do
      add(:sendgrid_id, :string)
      add(:category_id, references(:email_categories, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:sendgrid_emails, [:category_id]))
    create(unique_index(:sendgrid_emails, [:sendgrid_id]))

    flush()

    Emails.create_sendgrid_email(%{
      sendgrid_id: "b47d2224-792a-43d8-b4b2-f53b033d2f41",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "e5402f0b-a2c2-4786-955b-21d1cac6211d",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "f9448c06-ff05-4901-bb47-f21a7848c1e7",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "58de1c57-8028-4e0d-adb2-7349c01cf233",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "0e8a21f6-234f-4293-b5cf-fc9805042d82",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "75516ad9-3ce8-4742-bd70-1227ce3cba1d",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "9fc14299-96a0-4a4d-9917-c19f747270ff",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "39bbe1e0-9361-4505-89d6-60e3ef34fc3a",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "fcd40945-8a55-4459-94b9-401a995246fb",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "3fa051ce-c858-4bfa-806a-30980114f3e4",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "e1869afd-8cd1-4789-b444-dabff9b7f3f1",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "0f853118-211f-429f-8975-12f88c937855",
      category_id: 4
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "4ab4a0f8-79ac-4f82-9ee2-95db6fafb986",
      category_id: 2
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "79561f40-9939-406c-bdbe-0ecca63a1e1a",
      category_id: 2
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "c8573175-93a6-4f8c-b1bb-9368ad75981a",
      category_id: 1
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "e4c626a0-ad9a-4479-8228-6c02e7318789",
      category_id: 1
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "1395a042-ef5a-48a5-b890-c6340dd8eeff",
      category_id: 5
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "b91a66e1-d7f5-404f-804a-9a21f4ec70d4",
      category_id: 5
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "d92b0884-818d-4f54-926a-a529e5caa7d8",
      category_id: 3
    })

    Emails.create_sendgrid_email(%{
      sendgrid_id: "8474ef17-5836-4007-bf8d-77cb315a5e63",
      category_id: 3
    })
  end
end
