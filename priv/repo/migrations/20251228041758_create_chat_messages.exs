defmodule Echo.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chat_id, references(:chats, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :content, :text, null: false
      add :state, :string, null: false, default: "sent"
      add :deleted_at, :utc_datetime
      add :format, :string, null: false, default: "text"
      add :filename, :string, null: true
      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:user_id])
    create index(:messages, [:chat_id])
    create index(:messages, [:deleted_at])
    create index(:messages, [:state])
    create index(:messages, [:format])
  end
end
