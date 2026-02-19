defmodule Echo.Schemas.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "chats" do
    field :name, :string
    field :description, :string
    field :avatar_url, :string
    field :type, :string, default: "private"
    timestamps(type: :utc_datetime)

    belongs_to :creator, Echo.Schemas.User
    has_many :chat_members, Echo.Schemas.ChatMember
    has_many :messages, Echo.Schemas.Message
  end

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :type, :creator_id, :avatar_url, :description])
    |> validate_required([:type, :creator_id])
    |> validate_inclusion(:type, ["private", "group"])
    |> validate_name_based_on_type()
    |> foreign_key_constraint(:creator_id)
    |> validate_avatar_url(:avatar_url)
  end

  defp validate_avatar_url(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        put_change(changeset, field, default_group_avatar_url())

      _value ->
        changeset
    end
  end

  defp default_group_avatar_url do
    "https://storage.googleapis.com/echo-fiuba/avatars/groups/c20ba101-77d9-49b9-bb9e-fb363ceb0351-8f5b243d-a549-4af4-a89c-fef532aa7596.jpeg"
  end

  defp validate_name_based_on_type(changeset) do
    type = get_field(changeset, :type)
    name = get_field(changeset, :name)

    case type do
      "private" ->
        # Private chats should not have names
        if is_nil(name) do
          changeset
        else
          add_error(changeset, :name, "Private chats cannot have names")
        end

      "group" ->
        # Group chats must have names
        if is_nil(name) or String.trim(name) == "" do
          add_error(changeset, :name, "Group chats require a name")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  def private_chat_changeset(creator_id) do
    %__MODULE__{}
    |> changeset(%{
      type: "private",
      creator_id: creator_id,
      name: nil
    })
  end

  def group_chat_changeset(creator_id, name) do
    %__MODULE__{}
    |> changeset(%{
      type: "group",
      creator_id: creator_id,
      name: name
    })
  end


end
