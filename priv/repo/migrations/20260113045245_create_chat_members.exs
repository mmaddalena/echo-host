defmodule Echo.Repo.Migrations.CreateChatMembers do
  use Ecto.Migration

  def change do
    create table(:chat_members, primary_key: false) do
      add :chat_id, references(:chats, type: :binary_id, on_delete: :delete_all), primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), primary_key: true
      
      # Campos para tracking de lectura
      add :last_read_message_id, references(:messages, type: :binary_id, on_delete: :nilify_all),
          null: true
      add :last_read_at, :utc_datetime, null: true
      add :role, :string, null: false, default: "member" # "member" o "admin"
      
      timestamps(type: :utc_datetime)
    end

    create index(:chat_members, [:chat_id])
    create index(:chat_members, [:user_id])
    create index(:chat_members, [:last_read_message_id])
    
    # Índice útil para consultas de chats recientemente leídos
    create index(:chat_members, [:last_read_at])
    create index(:chat_members, [:role])
  end
end