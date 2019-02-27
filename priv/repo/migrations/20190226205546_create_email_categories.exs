defmodule OmegaBravera.Repo.Migrations.CreateEmailCategories do
  use Ecto.Migration

  alias OmegaBravera.{Repo, Emails, Emails.EmailCategory}

  def change do
    create table(:email_categories) do
      add(:title, :string)
      add(:description, :string)
    end

    flush()

    Repo.insert_all(
      EmailCategory,
      [
        %{
          title: "Supporter goals reached emails",
          description:
            "Notifications when someone you support has reached a goal or completed a challenge."
        },
        %{
          title: "Challenge Support Updates",
          description: "Emails to participants when supported pledge to your cause."
        },
        %{
          title: "Activity Updates",
          description: "When your activities or your team activities are completed and recorded."
        },
        %{
          title: "Platform Notifications",
          description: "Invites to be part of a team or a team member has joined."
        },
        %{
          title: "Inactivity Prompts",
          description: "When a participant has been inactive for a 5 to 7 days."
        }
      ]
    )
  end
end
