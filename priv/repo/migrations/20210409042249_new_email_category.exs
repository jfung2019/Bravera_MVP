defmodule OmegaBravera.Repo.Migrations.NewEmailCategory do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.Repo

  def change do
    Repo.insert_all("email_categories", [
      %{
        title: "News, Offers, Updates",
        description: "News, offers, product updates"
      }
    ])

    from(e in "email_categories", where: e.title == "Activity Updates")
    |> Repo.update_all(
      set: [
        description:
          "Activity / platform notifications (e.g. chat messages, rewards unlocked, rewards expiring soon)"
      ]
    )

    from(e in "email_categories", where: e.title == "Platform Notifications")
    |> Repo.update_all(
      set: [
        description:
          "Platform Notifications (essential emails needed for things like changing password)."
      ]
    )

    flush()

    platform_noti_category_id =
      from(e in "email_categories", where: e.title == "Platform Notifications", select: e.id)
      |> Repo.one!()

    activity_update_category_id =
      from(e in "email_categories", where: e.title == "Activity Updates", select: e.id)
      |> Repo.one!()

    from(user_email in "user_email_categories",
      where: user_email.category_id != ^platform_noti_category_id
    )
    |> Repo.update_all(set: [category_id: activity_update_category_id])

    from(email in "sendgrid_emails", where: email.category_id != ^platform_noti_category_id)
    |> Repo.update_all(set: [category_id: activity_update_category_id])

    all_categories = ["News, Offers, Updates", "Activity Updates", "Platform Notifications"]

    from(email in "email_categories", where: email.title not in ^all_categories)
    |> Repo.delete_all()
  end
end
