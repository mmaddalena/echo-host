defmodule Echo.Schemas.ChatMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  schema "chat_members" do
    timestamps(type: :utc_datetime)

    belongs_to :chat, Echo.Schemas.Chat, primary_key: true
    belongs_to :user, Echo.Schemas.User, primary_key: true

    belongs_to :last_read_message, Echo.Schemas.Message
    field :last_read_at, :utc_datetime
    # "member" o "admin"
    field :role, :string, default: "member"
  end

  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:chat_id, :user_id, :last_read_message_id, :role])
    |> validate_required([:chat_id, :user_id, :role])
    |> foreign_key_constraint(:chat_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:last_read_message_id)
  end
end
