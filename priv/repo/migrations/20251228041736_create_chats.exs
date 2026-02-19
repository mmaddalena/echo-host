defmodule Echo.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :type, :string, null: false, default: "private"
      add :avatar_url, :string
      add :creator_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    # Índices
    create index(:chats, [:type])
    create index(:chats, [:creator_id])
  end
end
