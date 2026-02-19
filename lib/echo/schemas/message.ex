defmodule Echo.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @states [:sent, :delivered, :read]

  schema "messages" do
    field :content, :string
    field :deleted_at, :utc_datetime
    field :state, Ecto.Enum, values: @states, default: :sent
    field :format, :string, default: "text"
    field :filename, :string
    timestamps(type: :utc_datetime)

    # Relaciones
    belongs_to :chat, Echo.Schemas.Chat
    belongs_to :user, Echo.Schemas.User
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :chat_id, :user_id, :state, :format, :filename])
    |> validate_required([:content, :chat_id, :user_id])
    |> foreign_key_constraint(:chat_id)
    |> foreign_key_constraint(:user_id)
    |> validate_length(:content, min: 1, max: 5000)
    |> validate_inclusion(:state, @states)
    |> validate_inclusion(:format, ["text", "image", "video", "audio", "file"])
  end

  def soft_delete_changeset(message) do
    change(message, %{
      deleted_at: DateTime.utc_now()
    })
  end
end
