defmodule Echo.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @username_regex ~r/^[a-zA-Z0-9_]+$/
  @email_regex ~r/^[^\s]+@[^\s]+$/

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
    field :last_seen_at, :utc_datetime
    timestamps(type: :utc_datetime)

    has_many :contacts, Echo.Schemas.Contact, foreign_key: :user_id
    has_many :blocked_contacts_as_blocker, Echo.Schemas.BlockedContact, foreign_key: :blocker_id
    has_many :blocked_contacts_as_blocked, Echo.Schemas.BlockedContact, foreign_key: :blocked_id
    has_many :chat_members, Echo.Schemas.ChatMember, foreign_key: :user_id
    has_many :created_chats, Echo.Schemas.Chat, foreign_key: :creator_id
    has_many :messages, Echo.Schemas.Message, foreign_key: :user_id
  end

  # Login
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> unique_constraint(:username, name: :users_username_index)
    |> validate_length(:username, min: 3, max: 50)
  end

  # Register
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :name, :avatar_url])
    |> validate_required([:username, :email, :password])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_length(:name, max: 30)
    |> validate_format(:username, @username_regex,
      message: "can only contain letters, numbers, and underscores"
    )
    |> validate_format(:email, @email_regex)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> validate_avatar_url(:avatar_url)
  end

  defp validate_avatar_url(changeset, field) do
  case get_field(changeset, field) do
    nil ->
      put_change(changeset, field, default_avatar_url())

    _value ->
      changeset
  end
end

defp default_avatar_url do
  "https://storage.googleapis.com/echo-fiuba/avatars/users/8234eff0-3e87-48b6-82de-7a7a0997a363-aa02bab7-b960-4dbf-b286-3229c150f0df.webp"
end

  defp put_password_hash(
         %Ecto.Changeset{
           valid?: true,
           changes: %{password: password}
         } = changeset
       ) do
    hash = Echo.Auth.Auth.hash_password(password)
    put_change(changeset, :password_hash, hash)
  end

  defp put_password_hash(changeset), do: changeset

  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, @username_regex,
        message: "can only contain letters, numbers, and underscores"
    )
    |> unique_constraint(:username)
  end

  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
  end


end
