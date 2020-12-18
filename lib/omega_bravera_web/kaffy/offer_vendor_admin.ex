defmodule OmegaBravera.OfferVendorAdmin do
  import Ecto.Query, warn: false

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
      vendor_id: %{label: "Vendor ID*"},
      email: %{label: "Email*"},
      cc: nil
    ]
  end

  def before_insert(conn, changeset) do
    %{private: %{:guardian_default_claims => %{"sub" => "partner_user:" <> partner_user_id}}} =
      conn

    {:ok, Ecto.Changeset.put_change(changeset, :partner_user_id, partner_user_id)}
  end
end
