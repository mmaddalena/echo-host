defmodule Echo.Repo.Migrations.CreateBlockedContacts do
  use Ecto.Migration

  def change do
    create table(:blocked_contacts, primary_key: false) do
      add :blocker_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false, primary_key: true
      add :blocked_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false, primary_key: true
      timestamps(type: :utc_datetime)
    end

    # Create composite index for queries by blocked_id
    create index(:blocked_contacts, [:blocked_id])

    # Constraint to prevent self-blocking
    create constraint(:blocked_contacts, :cannot_block_self,
      check: "blocker_id != blocked_id"
    )
  end
end
