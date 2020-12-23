defmodule OmegaBravera.OfferVendorAdmin do
  import Ecto.Query, warn: false

  def singular_name(_schema), do: "Claim ID"

  def custom_index_query(conn, _schema, query) do
    %{private: %{:guardian_default_claims => %{"sub" => "partner_user:" <> partner_user_id}}} =
      conn

    from(ov in query, left_join: pu in assoc(ov, :partner_user), where: pu.id == ^partner_user_id)
  end

  def index(_) do
    [
      vendor_id: nil,
      email: nil,
      cc: nil
    ]
  end

  def form_fields(_) do
    [
      vendor_id: %{
        label: "Claim ID*",
        help_text: "(Think of something memorable. Hint: 4-6 digits)"
      },
      email: %{
        label: "Email*",
        help_text:
          "(Enter an email to be sent successful claim details. Only enter x1 email. If left blank, no notification emails will be sent per reward claim verification)"
      },
      cc: %{
        help_text:
          "(Enter any additional email addresses that you may also wish to send successful claim emails)"
      }
    ]
  end

  def before_insert(conn, changeset) do
    %{private: %{:guardian_default_claims => %{"sub" => "partner_user:" <> partner_user_id}}} =
      conn

    {:ok, Ecto.Changeset.put_change(changeset, :partner_user_id, partner_user_id)}
  end
end
