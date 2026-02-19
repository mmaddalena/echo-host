defmodule Echo.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :nickname, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :contact_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:contacts, [:user_id, :contact_id])
    create index(:contacts, [:user_id])
    create index(:contacts, [:contact_id])

    # Constraint para evitar auto-contacto
    execute """
      ALTER TABLE contacts
      ADD CONSTRAINT contact_cannot_be_self
      CHECK (user_id != contact_id)
    """
  end
end
