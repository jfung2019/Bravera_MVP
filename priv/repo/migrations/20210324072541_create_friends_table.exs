defmodule OmegaBravera.Repo.Migrations.CreateFriendsTable do
  use Ecto.Migration

  def change do
    create table("friends", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false, default: "pending"
      add :receiver_id, references(:users, on_delete: :delete_all), null: false
      add :requester_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:friends, [:receiver_id, :requester_id])
    create constraint(:friends, :cannot_friend_self, check: "receiver_id <> requester_id")
  end
end
